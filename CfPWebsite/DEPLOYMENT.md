# CfP Website Deployment

## Overview
The CfP website is deployed to GitHub Pages at `tryswift.jp/cfp` alongside the main website. Both sites are built and deployed together using a single GitHub Actions workflow.

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

## Deployment

### Automatic Deployment (GitHub Actions)

The CfP website is automatically deployed with the main website when changes are pushed to the `main` branch. The workflow:

1. Builds the main Website using Xcode
2. Builds the CfP website using Swift
3. Runs `prepare-for-github-pages.sh` to add `/cfp` prefix to all paths
4. Copies CfP build output to `Website/Build/cfp/`
5. Deploys the combined `Website/Build` directory to GitHub Pages

**Triggers:**
- Push to `main` branch with changes to:
  - `Website/Sources/**` or `Website/Assets/**`
  - `CfPWebsite/Sources/**` or `CfPWebsite/Assets/**`
  - `SharedModels/**`
- Manual workflow dispatch

See [.github/workflows/deploy_website.yml](../.github/workflows/deploy_website.yml) for details.

### Manual Deployment

If you need to deploy manually:

```bash
# Build main website
cd Website
swift run

# Build CfP website
cd ../CfPWebsite
./prepare-for-github-pages.sh

# Copy to main website build
mkdir -p ../Website/Build/cfp
cp -r Build/* ../Website/Build/cfp/

# Deploy Website/Build to GitHub Pages
```

### Backend Deployment (Fly.io)
Update the FRONTEND_URL environment variable on Fly.io:

```bash
cd ../Server
fly secrets set FRONTEND_URL=https://tryswift.jp/cfp -a tryswift-cfp-api
```

Deploy the updated backend:
```bash
fly deploy -c fly.toml -a tryswift-cfp-api
```

### Verify Deployment

1. Visit `https://tryswift.jp/cfp/`
2. Test OAuth login flow
3. Verify all pages load correctly
4. Check that assets (CSS, images) load properly

## Testing Locally

To test the CfP website locally:

```bash
cd CfPWebsite
swift run
# Site will be built to Build/ directory

# Serve locally (paths won't have /cfp prefix in local build)
python3 -m http.server 8080 -d Build
# Then visit: http://localhost:8080/
```

Note: Local testing uses root paths, not `/cfp` prefix. The `/cfp` prefix is only added by `prepare-for-github-pages.sh` during deployment.

## Architecture Notes

- **Frontend**: CfP website is a static site deployed to GitHub Pages at `/cfp/`
- **Backend**: API remains on Fly.io at `tryswift-cfp-api.fly.dev`
- **OAuth**: Tokens are passed via URL params (cross-domain compatible)
- **CORS**: Backend configured to allow requests from `tryswift.jp`
- **Paths**: All deployed CfP website paths start with `/cfp/`
- **Build**: `prepare-for-github-pages.sh` post-processes HTML to add `/cfp` prefix
