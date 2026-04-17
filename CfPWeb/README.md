# CfPWeb

Static frontend build for `cfp.tryswift.jp`.

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

## Build

```bash
cd CfPWeb
swift run CfPWeb
```

This generates a static site into `CfPWeb/Build` by default.

Optional overrides:

```bash
swift run CfPWeb --output Dist --public-dir Public --api-base-url https://api.tryswift.jp
```

## Current Scope

This package currently provides:

- a static HTML build generated from `Elementary`
- separate public routes for key CfP pages
- login/logout wiring to the API
- API-backed session bootstrap
- generated rewrite hints for deep links and legacy `/cfp/**` paths

It is intentionally a scaffold for the ongoing migration, while removing the need for a Vapor process in front of the frontend.

## Related Docs

- [Vapor Removal Handoff](/Users/soya.ichikawa/Projects/Private/try-swift-tokyo/CfPWeb/VAPOR_REMOVAL_HANDOFF.md)
