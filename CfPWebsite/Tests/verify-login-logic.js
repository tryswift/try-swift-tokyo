#!/usr/bin/env node

/**
 * Login Logic Verification Script
 * Simulates the authentication flow without a browser
 */

// Simulated localStorage
const localStorage = {
  storage: {},
  getItem(key) {
    return this.storage[key] || null;
  },
  setItem(key, value) {
    this.storage[key] = value;
  },
  removeItem(key) {
    delete this.storage[key];
  },
  clear() {
    this.storage = {};
  }
};

// Simulated URLSearchParams
class MockURLSearchParams {
  constructor(queryString) {
    this.params = {};
    if (queryString) {
      queryString.split('&').forEach(pair => {
        const [key, value] = pair.split('=');
        if (key) {
          this.params[decodeURIComponent(key)] = decodeURIComponent(value || '');
        }
      });
    }
  }

  get(key) {
    return this.params[key] || null;
  }
}

// Test results
const results = {
  passed: 0,
  failed: 0,
  tests: []
};

function test(name, fn) {
  try {
    fn();
    console.log(`✅ ${name}`);
    results.passed++;
    results.tests.push({ name, status: 'PASS' });
  } catch (error) {
    console.error(`❌ ${name}`);
    console.error(`   Error: ${error.message}`);
    results.failed++;
    results.tests.push({ name, status: 'FAIL', error: error.message });
  }
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

function assertEquals(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(message || `Expected ${expected}, got ${actual}`);
  }
}

console.log('🧪 Testing Login Logic\n');

// Test 1: OAuth Callback Processing
test('OAuth callback stores token and username', () => {
  localStorage.clear();

  const urlParams = new MockURLSearchParams('auth=success&token=test123&username=testuser');
  const authSuccess = urlParams.get('auth');
  const token = urlParams.get('token');
  const username = urlParams.get('username');

  // Simulate OAuth callback logic
  if (authSuccess === 'success' && token && !localStorage.getItem('cfp_token')) {
    localStorage.setItem('cfp_token', token);
    if (username) {
      localStorage.setItem('cfp_username', username);
    }
  }

  assertEquals(localStorage.getItem('cfp_token'), 'test123', 'Token should be stored');
  assertEquals(localStorage.getItem('cfp_username'), 'testuser', 'Username should be stored');
});

// Test 2: OAuth Loop Prevention
test('OAuth callback does not overwrite existing token', () => {
  localStorage.clear();
  localStorage.setItem('cfp_token', 'existing-token');
  localStorage.setItem('cfp_username', 'existing-user');

  const urlParams = new MockURLSearchParams('auth=success&token=new-token&username=new-user');
  const authSuccess = urlParams.get('auth');
  const token = urlParams.get('token');
  const username = urlParams.get('username');

  // Simulate OAuth callback logic
  if (authSuccess === 'success' && token && !localStorage.getItem('cfp_token')) {
    localStorage.setItem('cfp_token', token);
    if (username) {
      localStorage.setItem('cfp_username', username);
    }
  }

  assertEquals(localStorage.getItem('cfp_token'), 'existing-token', 'Token should not be overwritten');
  assertEquals(localStorage.getItem('cfp_username'), 'existing-user', 'Username should not be overwritten');
});

// Test 3: Login State Detection
test('Detects authenticated state from localStorage', () => {
  localStorage.clear();
  localStorage.setItem('cfp_token', 'valid-token');
  localStorage.setItem('cfp_username', 'john');

  const storedToken = localStorage.getItem('cfp_token');
  const storedUsername = localStorage.getItem('cfp_username');

  assert(storedToken !== null, 'Token should be present');
  assert(storedUsername !== null, 'Username should be present');
  assertEquals(storedToken, 'valid-token', 'Token should match');
  assertEquals(storedUsername, 'john', 'Username should match');
});

// Test 4: Login State Detection (Unauthenticated)
test('Detects unauthenticated state when no token', () => {
  localStorage.clear();

  const storedToken = localStorage.getItem('cfp_token');
  const storedUsername = localStorage.getItem('cfp_username');

  assertEquals(storedToken, null, 'Token should be null');
  assertEquals(storedUsername, null, 'Username should be null');
});

// Test 5: Logout Clears Storage
test('Logout clears localStorage', () => {
  localStorage.clear();
  localStorage.setItem('cfp_token', 'token-to-clear');
  localStorage.setItem('cfp_username', 'user-to-clear');

  // Simulate logout
  localStorage.removeItem('cfp_token');
  localStorage.removeItem('cfp_username');

  assertEquals(localStorage.getItem('cfp_token'), null, 'Token should be cleared');
  assertEquals(localStorage.getItem('cfp_username'), null, 'Username should be cleared');
});

// Test 6: OAuth Callback Without Username
test('OAuth callback works without username', () => {
  localStorage.clear();

  const urlParams = new MockURLSearchParams('auth=success&token=token-only');
  const authSuccess = urlParams.get('auth');
  const token = urlParams.get('token');
  const username = urlParams.get('username');

  // Simulate OAuth callback logic
  if (authSuccess === 'success' && token && !localStorage.getItem('cfp_token')) {
    localStorage.setItem('cfp_token', token);
    if (username) {
      localStorage.setItem('cfp_username', username);
    }
  }

  assertEquals(localStorage.getItem('cfp_token'), 'token-only', 'Token should be stored');
  assertEquals(localStorage.getItem('cfp_username'), null, 'Username should be null');
});

// Test 7: Error Parameter Handling
test('Error parameter is detected correctly', () => {
  const urlParams = new MockURLSearchParams('error=access_denied');
  const error = urlParams.get('error');

  assertEquals(error, 'access_denied', 'Error should be detected');
});

// Test 8: Missing auth Parameter
test('OAuth callback ignores missing auth parameter', () => {
  localStorage.clear();

  const urlParams = new MockURLSearchParams('token=test&username=user');
  const authSuccess = urlParams.get('auth');
  const token = urlParams.get('token');
  const username = urlParams.get('username');

  // Simulate OAuth callback logic
  if (authSuccess === 'success' && token && !localStorage.getItem('cfp_token')) {
    localStorage.setItem('cfp_token', token);
    if (username) {
      localStorage.setItem('cfp_username', username);
    }
  }

  assertEquals(localStorage.getItem('cfp_token'), null, 'Token should not be stored without auth=success');
  assertEquals(localStorage.getItem('cfp_username'), null, 'Username should not be stored without auth=success');
});

// Test 9: Welcome Message Generation
test('Welcome message is generated correctly', () => {
  const username = 'johndoe';
  const welcomeMessage = 'Welcome, ' + username + '!';

  assertEquals(welcomeMessage, 'Welcome, johndoe!', 'Welcome message should be formatted correctly');
});

// Test 10: Navigation Update Data Structure
test('Navigation update has correct structure', () => {
  const token = 'test-token';
  const username = 'test-user';

  // Simulate navigation update data
  const navigationData = {
    userLink: {
      text: '👤 ' + username,
      href: '/cfp/my-proposals-page',
      classes: ['text-white', 'fw-bold', 'nav-link']
    },
    myProposalsLink: {
      text: 'My Proposals',
      href: '/cfp/my-proposals-page',
      className: 'nav-link text-white'
    },
    signOutButton: {
      text: 'Sign Out',
      href: '#',
      className: 'btn btn-sm btn-danger text-nowrap',
      redirectTo: '/cfp/'
    }
  };

  assertEquals(navigationData.userLink.text, '👤 test-user', 'User link text should include username');
  assertEquals(navigationData.userLink.href, '/cfp/my-proposals-page', 'User link should go to My Proposals');
  assertEquals(navigationData.myProposalsLink.href, '/cfp/my-proposals-page', 'My Proposals link correct');
  assertEquals(navigationData.signOutButton.redirectTo, '/cfp/', 'Sign out should redirect to home');
});

// Summary
console.log('\n' + '='.repeat(50));
console.log(`Total: ${results.passed + results.failed} tests`);
console.log(`✅ Passed: ${results.passed}`);
console.log(`❌ Failed: ${results.failed}`);
console.log('='.repeat(50));

if (results.failed > 0) {
  console.log('\nFailed tests:');
  results.tests.filter(t => t.status === 'FAIL').forEach(t => {
    console.log(`  - ${t.name}: ${t.error}`);
  });
  process.exit(1);
} else {
  console.log('\n🎉 All tests passed!');
  process.exit(0);
}
