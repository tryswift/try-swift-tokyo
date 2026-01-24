# CfP Website Deployment to GitHub Pages

## Overview
The CfP website has been migrated from Fly.io (`cfp.tryswift.jp`) to GitHub Pages at `tryswift.jp/cfp`.

## Changes Made

### 1. Frontend Changes (CfPWebsite)
- Updated base URL from `https://cfp.tryswift.jp` to `https://tryswift.jp`
- Added `/cfp` prefix to all internal links and asset paths
- Created `prepare-for-github-pages.sh` script to post-process build output
- Updated OGP/Twitter card image URLs to use new path

### 2. Backend Changes (Server)
- Updated default `FRONTEND_URL` from `https://tryswift-cfp-website.fly.dev` to `https://tryswift.jp/cfp`
- Updated OAuth redirect paths to use `/login-page` instead of `/login`
- Updated CORS configuration to use `.originBased` for better security

### 3. Files Modified
- `CfPWebsite/Sources/CfPWebsite.swift` - Updated site URL and favicon path
- `CfPWebsite/Sources/Layouts/CfPLayout.swift` - Updated OGP images and internal paths
- `CfPWebsite/Sources/Components/Navigation.swift` - Updated logo link to `/cfp/`
- `Server/Sources/Server/Controllers/AuthController.swift` - Updated redirect URLs
- `Server/Sources/Server/configure.swift` - Updated CORS configuration

## Deployment Steps

### Step 1: Build the CfP Website
```bash
cd CfPWebsite
./prepare-for-github-pages.sh
```

This script will:
1. Build the static site
2. Update all paths to include `/cfp` prefix
3. Place the output in the `Build` directory

### Step 2: Deploy Backend to Fly.io
Update the FRONTEND_URL environment variable on Fly.io:

```bash
cd ../Server
fly secrets set FRONTEND_URL=https://tryswift.jp/cfp -a tryswift-cfp-api
```

Deploy the updated backend:
```bash
fly deploy -c fly.toml -a tryswift-cfp-api
```

### Step 3: Update GitHub OAuth Callback URL
Go to GitHub OAuth App settings and update the callback URL:
- Old: `https://tryswift-cfp-api.fly.dev/api/v1/auth/github/callback`
- Keep as is (backend URL doesn't change)

### Step 4: Deploy to GitHub Pages
The CfP website needs to be deployed alongside the main website. There are two options:

#### Option A: Manual Copy (for testing)
```bash
cd ../CfPWebsite
# Create cfp directory in main Website Build folder
mkdir -p ../Website/Build/cfp
# Copy all built files
cp -r Build/* ../Website/Build/cfp/
```

Then deploy the Website to GitHub Pages as usual.

#### Option B: Automated via GitHub Actions
Create or update `.github/workflows/deploy-pages.yml` to include:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Main Website
        run: |
          cd Website
          swift run

      - name: Build CfP Website
        run: |
          cd CfPWebsite
          ./prepare-for-github-pages.sh

      - name: Copy CfP to main build
        run: |
          mkdir -p Website/Build/cfp
          cp -r CfPWebsite/Build/* Website/Build/cfp/

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./Website/Build
```

### Step 5: Verify Deployment
1. Visit `https://tryswift.jp/cfp/`
2. Test OAuth login flow
3. Verify all pages load correctly
4. Check that assets (CSS, images) load properly

## Post-Deployment

### Remove Fly.io CfP Website App (Optional)
Once the GitHub Pages deployment is verified and working:

```bash
# List apps to confirm
fly apps list

# Destroy the old CfP website app
fly apps destroy tryswift-cfp-website
```

### Update DNS (if needed)
Remove the CNAME record for `cfp.tryswift.jp` if it exists.

## Testing Locally

To test the CfP website locally with the `/cfp` base path:

```bash
cd CfPWebsite
./prepare-for-github-pages.sh

# Serve with a web server that supports the /cfp path
python3 -m http.server 8080 -d Build
# Then visit: http://localhost:8080/
```

Note: Local testing won't perfectly replicate the `/cfp` path structure. For accurate testing, deploy to a staging environment or GitHub Pages.

## Rollback Plan

If issues arise, you can quickly rollback:

1. Revert the backend FRONTEND_URL:
   ```bash
   fly secrets set FRONTEND_URL=https://cfp.tryswift.jp -a tryswift-cfp-api
   ```

2. Redeploy the old backend version:
   ```bash
   fly deploy -a tryswift-cfp-api --image <previous-image-id>
   ```

3. The Fly.io CfP website app at `cfp.tryswift.jp` will still be running if not destroyed.

## Notes

- The backend API remains on Fly.io at `tryswift-cfp-api.fly.dev`
- OAuth flow works across domains because tokens are passed via URL params
- CORS is configured to allow requests from `tryswift.jp`
- All CfP website paths now start with `/cfp/` when deployed to GitHub Pages
