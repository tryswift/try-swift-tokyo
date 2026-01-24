# CfP Website Testing Procedures

## Pre-Deployment Testing Checklist

### Build Verification

Run automated Swift tests:
```bash
cd CfPWebsite
swift test
```

All tests must pass before proceeding.

### Local Build Test

```bash
cd CfPWebsite
swift run
```

**Verify:**
- [ ] Build completes without errors
- [ ] `Build/` directory created
- [ ] All HTML files present: cf-p-home, login-page, submit-page, my-proposals-page, guidelines-page
- [ ] Assets present: css/, js/, images/

### Production Build Test

```bash
cd CfPWebsite
./prepare-for-github-pages.sh
```

**Verify:**
- [ ] Script completes successfully
- [ ] All HTML files updated with `/cfp/` prefix
- [ ] sitemap.xml and feed.rss updated

### Local Manual Testing

Start local server:
```bash
python3 -m http.server 8080 -d Build
```

#### Test 1: Unauthenticated State
1. Navigate to http://localhost:8080/login-page
2. **Verify:**
   - [ ] Login form is visible immediately (no flash of logged-in content)
   - [ ] "Sign in with GitHub" button present
   - [ ] Navigation bar shows "Login with GitHub" button
   - [ ] No JavaScript console errors

#### Test 2: OAuth Callback Simulation
1. Visit: http://localhost:8080/login-page?auth=success&token=test123&username=testuser
2. **Verify:**
   - [ ] Page automatically redirects to clean URL (no query params)
   - [ ] Login form is hidden
   - [ ] Logged-in view is visible
   - [ ] Welcome message shows "Welcome, testuser!"
   - [ ] "Submit a Proposal" button visible
   - [ ] "My Proposals" button visible
   - [ ] "Logout" link visible
   - [ ] No JavaScript console errors

3. Open browser DevTools > Application > Local Storage
4. **Verify:**
   - [ ] `cfp_token` = "test123"
   - [ ] `cfp_username` = "testuser"

#### Test 3: Authenticated State Persistence
1. With credentials in localStorage, reload page (F5)
2. **Verify:**
   - [ ] Logged-in view shows immediately
   - [ ] No flash of login form
   - [ ] Username displayed correctly

3. Navigate to http://localhost:8080/submit-page
4. **Verify:**
   - [ ] Submit form is shown (not login prompt)

#### Test 4: Navigation Bar Updates
1. With credentials in localStorage, navigate to any page
2. **Verify:**
   - [ ] Navigation shows user icon + username (e.g., "👤 testuser")
   - [ ] "My Proposals" link present
   - [ ] Red "Sign Out" button present
   - [ ] "Login with GitHub" button is replaced (not shown)

#### Test 5: Logout Flow
1. Click "Logout" link on login page
2. **Verify:**
   - [ ] Page reloads
   - [ ] Login form visible again
   - [ ] Logged-in view hidden
   - [ ] localStorage cleared (check DevTools)

3. Click "Sign Out" in navigation bar
4. **Verify:**
   - [ ] Redirects to home page (/cfp/)
   - [ ] localStorage cleared
   - [ ] Navigation shows "Login with GitHub" button

#### Test 6: Error Handling
1. Visit: http://localhost:8080/login-page?error=access_denied
2. **Verify:**
   - [ ] Alert dialog shows error message
   - [ ] Login form remains visible
   - [ ] No credentials in localStorage

#### Test 7: OAuth Loop Prevention
1. Set token in localStorage manually (DevTools console):
   ```javascript
   localStorage.setItem('cfp_token', 'existing-token')
   localStorage.setItem('cfp_username', 'existing-user')
   ```
2. Visit: http://localhost:8080/login-page?auth=success&token=new-token&username=new-user
3. **Verify:**
   - [ ] Credentials NOT updated (still "existing-token")
   - [ ] No redirect loop
   - [ ] Page loads normally

### Production Testing (After Deployment)

Test at: https://tryswift.jp/cfp/login-page

#### Real OAuth Flow Test
1. Click "Sign in with GitHub"
2. Authorize on GitHub
3. **Verify:**
   - [ ] Redirected back to login-page with auth params
   - [ ] Automatically redirects to clean URL
   - [ ] Logged-in view shown
   - [ ] Username displayed correctly
   - [ ] Navigation bar updated

4. Navigate to other pages:
   - [ ] Home: https://tryswift.jp/cfp/
   - [ ] Submit: https://tryswift.jp/cfp/submit-page
   - [ ] My Proposals: https://tryswift.jp/cfp/my-proposals-page

5. **Verify all pages:**
   - [ ] Navigation bar shows user info
   - [ ] Protected pages accessible (not redirected to login)
   - [ ] All links have correct `/cfp/` prefix

#### Cross-Browser Testing
- [ ] Chrome
- [ ] Safari
- [ ] Firefox
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

#### Logout Production Test
1. Sign out from navigation
2. **Verify:**
   - [ ] Redirects to home
   - [ ] Navigation shows login button
   - [ ] Protected pages redirect to login

## Test Results

Document test results before deployment:

**Date**: _________
**Tester**: _________
**Branch**: _________
**Commit**: _________

**Swift Tests**: ☐ Pass ☐ Fail
**Build Test**: ☐ Pass ☐ Fail
**Local Manual Tests**: ☐ Pass ☐ Fail

**Notes**:
_________________________________
_________________________________

**Approved for Deployment**: ☐ Yes ☐ No
**Approver**: _________
