# trySwiftCfP Server Deployment Guide

## Fly.io Deployment

### Prerequisites

1. Install Fly CLI:
   ```bash
   brew install flyctl
   ```

2. Login to Fly.io:
   ```bash
   fly auth login
   ```

### Initial Setup

1. **Create the app** (from the Server directory):
   ```bash
   cd Server
   fly apps create tryswift-cfp-api
   ```

2. **Create a PostgreSQL database**:
   ```bash
   fly postgres create --name tryswift-cfp-db --region nrt
   ```

3. **Attach the database to the app**:
   ```bash
   fly postgres attach tryswift-cfp-db --app tryswift-cfp-api
   ```
   This will automatically set the `DATABASE_URL` secret.

4. **Set required secrets**:
   ```bash
   # JWT Secret (generate a secure random string)
   fly secrets set JWT_SECRET="$(openssl rand -base64 32)" --app tryswift-cfp-api
   
   # GitHub OAuth credentials
   fly secrets set GITHUB_CLIENT_ID="your-github-client-id" --app tryswift-cfp-api
   fly secrets set GITHUB_CLIENT_SECRET="your-github-client-secret" --app tryswift-cfp-api
   
   # GitHub Organization and Team for admin access
   fly secrets set GITHUB_ORG_NAME="tryswift" --app tryswift-cfp-api
   fly secrets set GITHUB_TEAM_SLUG="tokyo" --app tryswift-cfp-api
   
   # Callback URL (update after deployment)
   fly secrets set GITHUB_CALLBACK_URL="https://tryswift-cfp-api.fly.dev/api/v1/auth/github/callback" --app tryswift-cfp-api
   ```

### Deploy

**Important**: The Dockerfile needs access to the `MyLibrary` directory, so we need to deploy from the project root:

```bash
# From project root directory
fly deploy --config Server/fly.toml --dockerfile Server/Dockerfile
```

Or create a root-level fly.toml:

```bash
# Alternative: Deploy from Server directory with build context
cd Server
fly deploy --build-arg CONTEXT=..
```

### Verify Deployment

```bash
# Check app status
fly status --app tryswift-cfp-api

# View logs
fly logs --app tryswift-cfp-api

# Check health endpoint
curl https://tryswift-cfp-api.fly.dev/health
```

### Run Migrations

Migrations run automatically on app startup. To run them manually:

```bash
fly ssh console --app tryswift-cfp-api
./Server migrate --yes
```

## GitHub OAuth Setup

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App:
   - **Application name**: trySwift CfP
   - **Homepage URL**: https://cfp.tryswift.jp
   - **Authorization callback URL**: https://tryswift-cfp-api.fly.dev/api/v1/auth/github/callback
3. Copy the Client ID and Client Secret to Fly.io secrets

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes (auto-set by Fly) |
| `JWT_SECRET` | Secret key for JWT signing | Yes |
| `GITHUB_CLIENT_ID` | GitHub OAuth App Client ID | Yes |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth App Client Secret | Yes |
| `GITHUB_CALLBACK_URL` | OAuth callback URL | Yes |
| `GITHUB_ORG_NAME` | GitHub organization name (default: tryswift) | No |
| `GITHUB_TEAM_SLUG` | Team slug for admin access (default: tokyo) | No |
| `LOG_LEVEL` | Logging level (default: info) | No |

## Scaling

```bash
# Scale to 2 machines
fly scale count 2 --app tryswift-cfp-api

# Scale memory
fly scale memory 1024 --app tryswift-cfp-api
```

## Monitoring

```bash
# View metrics
fly dashboard --app tryswift-cfp-api

# Check database
fly postgres connect --app tryswift-cfp-db
```
