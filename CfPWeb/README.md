# CfPWeb

Standalone frontend for `cfp.tryswift.jp`.

## Purpose

This package is the receiving side of the CfP split:

- `CfPWeb` renders the web UI
- `Server` evolves toward `api.tryswift.jp`

The frontend does not inspect auth cookies directly. It reads auth state from:

- `GET /api/v1/auth/me`

and starts login via:

- `GET /api/v1/auth/github`

## Configuration

Set the API base URL with:

```bash
export CFP_API_BASE_URL="https://api.tryswift.jp"
```

Default:

```text
https://api.tryswift.jp
```

## Local Run

```bash
cd CfPWeb
swift run
```

## Current Scope

This package currently provides:

- a standalone Vapor frontend app
- separate public routes for key CfP pages
- login/logout wiring to the API
- API-backed session bootstrap
- preview fetching for speaker and organizer pages

It is intentionally a scaffold for the ongoing migration, not yet a full feature-complete replacement for the old SSR pages.
