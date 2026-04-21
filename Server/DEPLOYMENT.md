# trySwift API Server Deployment Guide

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

1. **Create the production app**:

   ```bash
   fly apps create tryswift-api-prod
   ```

2. **Create a PostgreSQL database**:

   ```bash
   fly postgres create --name tryswift-api-db-prod --region nrt
   ```

3. **Attach the database to the app**:

   ```bash
   fly postgres attach tryswift-api-db-prod --app tryswift-api-prod
   ```

   This will automatically set the `DATABASE_URL` secret.

4. **Set required secrets**:

   ```bash
   # JWT Secret (generate a secure random string)
   fly secrets set JWT_SECRET="$(openssl rand -base64 32)" --app tryswift-api-prod

   # GitHub OAuth credentials
   fly secrets set GITHUB_CLIENT_ID="your-github-client-id" --app tryswift-api-prod
   fly secrets set GITHUB_CLIENT_SECRET="your-github-client-secret" --app tryswift-api-prod

   # GitHub Organization and Team for admin access
   fly secrets set GITHUB_ORG="tryswift" --app tryswift-api-prod
   fly secrets set GITHUB_TEAM="tokyo" --app tryswift-api-prod

   # Frontend URL (for cookie domain and redirect)
   fly secrets set FRONTEND_URL="https://cfp.tryswift.jp" --app tryswift-api-prod

   # Production environment (enables Secure cookies)
   fly secrets set APP_ENV="production" --app tryswift-api-prod

   # Callback URL
   fly secrets set GITHUB_CALLBACK_URL="https://api.tryswift.jp/api/v1/auth/github/callback" --app tryswift-api-prod
   ```

### Deploy

**Important**: Deploy from the project root so Docker can access all workspace packages:

```bash
# From the project root directory
fly deploy --config fly.production.toml
```

### Verify Deployment

```bash
# Check app status
fly status --app tryswift-api-prod

# View logs
fly logs --app tryswift-api-prod

# Check health endpoint
curl https://tryswift-api-prod.fly.dev/health
```

### Run Migrations

Migrations run automatically on app startup. To run them manually:

```bash
fly ssh console --app tryswift-api-prod
./Server migrate --yes
```

## GitHub OAuth Setup

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App:
   - **Application name**: trySwift API
   - **Homepage URL**: <https://tryswift.jp>
   - **Authorization callback URL**: <https://api.tryswift.jp/api/v1/auth/github/callback>
3. Copy the Client ID and Client Secret to Fly.io secrets

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes (auto-set by Fly) |
| `JWT_SECRET` | Secret key for JWT signing | Yes |
| `GITHUB_CLIENT_ID` | GitHub OAuth App Client ID | Yes |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth App Client Secret | Yes |
| `GITHUB_CALLBACK_URL` | OAuth callback URL | Yes |
| `FRONTEND_URL` | Frontend URL for cookie domain (e.g., `https://cfp.tryswift.jp`) | Yes |
| `APP_ENV` | Set to `production` for secure cookies | Yes |
| `API_BASE_URL` | API server URL (e.g., `https://api.tryswift.jp`) | No |
| `GITHUB_ORG` | GitHub organization name (default: tryswift) | No |
| `GITHUB_TEAM` | Team slug for admin access (default: tokyo) | No |
| `GITHUB_ORG_NAME` | Legacy alias for `GITHUB_ORG` | No |
| `GITHUB_TEAM_SLUG` | Legacy alias for `GITHUB_TEAM` | No |
| `LOG_LEVEL` | Logging level (default: info) | No |

## Scaling

```bash
# Scale to 2 machines
fly scale count 2 --app tryswift-api-prod

# Scale memory
fly scale memory 1024 --app tryswift-api-prod
```

## Monitoring

```bash
# View metrics
fly dashboard --app tryswift-api-prod

# Check database
fly postgres connect --app tryswift-api-db-prod
```

## Custom Domain (api.tryswift.jp)

### Fly.io Certificate

```bash
fly certs create api.tryswift.jp --app tryswift-api-prod
fly certs show api.tryswift.jp --app tryswift-api-prod
```

### Cloudflare DNS

1. Add a CNAME record: `api` → `tryswift-api-prod.fly.dev` (Proxy enabled / orange cloud)
2. SSL/TLS mode: **Full (Strict)** (fly.io terminates TLS on its end)
3. Cache: API responses are not cached by default (dynamic content bypass)
4. Security: Enable WAF / Rate Limiting as needed

### Update OAuth Callback URL

After the domain is active, update the callback URL:

```bash
fly secrets set GITHUB_CALLBACK_URL="https://api.tryswift.jp/api/v1/auth/github/callback" --app tryswift-api-prod
```

Also update the callback URL in the [GitHub OAuth App settings](https://github.com/settings/developers).
