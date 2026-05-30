# Design: Move the 2026 site to /2026 and show an Apple-style "We'll be back soon" maintenance page at root

Date: 2026-05-30
Status: Approved

## Goal

After the April 2026 conference, archive the current conference homepage (now served at root `/`) under `/2026`, and replace root `/` with a minimal maintenance landing page modeled on Apple Store's "We'll be back soon." screen. The Apple logo position is occupied by the try! Swift Tokyo mascot, Riko.

## Scope

- Target codebase: `Web/Sources/WebConference` (the live Ignite static site deployed to GitHub Pages via `.github/workflows/deploy_website.yml`).
- Root `/` only is swapped. All other pages keep working: `/2026`, past years (`/2025`, `/2024`, ...), `/faq`, `/code-of-conduct`, `/privacy-policy`, `/booth-map`, and their `/en` variants.
- The legacy top-level `Website/` directory is out of scope and left untouched.

## Decisions (from brainstorming)

- Target: WebConference (production).
- Scope: root only — other pages stay live.
- Maintenance copy: Apple's original wording, English only.

## Architecture / Routing change

### `Pages/Home.swift`

Currently `generatePath` special-cases the latest year so it renders at `/`:

```swift
static func generatePath(for year: ConferenceYear, language: SupportedLanguage) -> String {
  var pathComponents = [String]()
  if year != .latest {
    pathComponents.append(String(year.rawValue))
  }
  if language != .ja {
    pathComponents.append(language.rawValue)
  }
  return "/" + pathComponents.joined(separator: "/")
}
```

Change: **always include the year component** (drop the `.latest` special case):

```swift
static func generatePath(for year: ConferenceYear, language: SupportedLanguage) -> String {
  var pathComponents = [String(year.rawValue)]
  if language != .ja {
    pathComponents.append(language.rawValue)
  }
  return "/" + pathComponents.joined(separator: "/")
}
```

Effect:
- 2026 ja → `/2026`, 2026 en → `/2026/en` (previously `/` and `/en`).
- Past years unchanged (already `/YYYY`).
- Root `/` is now free for the maintenance page.
- All "home"/logo links across nav bars and footers are built via `Home.generatePath(for: .latest, ...)`, so they automatically point to `/2026` — **no manual link edits needed** in `MainNavigationBar`, `FAQ`, `CodeOfConduct`, `PrivacyPolicy`, `Retro2016NavigationBar`.

### `ConferenceWebsite.swift`

- Change `homePage`:
  - from `var homePage = Home(year: .latest, language: .ja)`
  - to `var homePage = Maintenance()`
- The `staticPages` year loop is unchanged: it already emits `Home(year: .year2026, ...)`, which now resolves to `/2026` and `/2026/en`.
- `LegacyHome` (path `/_en`) is a redirect shim whose `MainLayout` rule rewrites `_en` → `/en`. Since `/en` no longer exists, update the redirect target to `/2026/en` (or remove `LegacyHome` if no longer needed). Implementation will pick the smaller correct change after re-reading the redirect logic in `MainLayout`.

## Maintenance page (new file `Pages/Maintenance.swift`)

A `StaticPage` with `path = "/"`, used as `homePage`.

Layout (Apple Store "We'll be back soon." style):
- Full-viewport flexbox container, vertically and horizontally centered, white background, dark text.
- No navigation bar, no footer (intentionally bare).
- Riko image `/images/riko.png` at top (Apple-logo position), ~100–120px.
- Heading: **"We'll be back soon."** (large, semibold).
- Subtext: **"We're making changes to the Conference and we'll be back soon. Please check back later."** (Apple wording with "the Store" replaced by "the Conference").

Implementation notes:
- Uses the site's default `MainLayout`, which only injects `<head>` OGP meta and renders the page body into `<body>` (nav/footer are added per-page elsewhere, not by the layout) — so reusing it yields a clean bare page.
- Centering CSS applied via Ignite style modifiers on the container, or a small inline `<style>` block if modifiers are insufficient. Exact Ignite API chosen during implementation.
- `riko.png` is already served from `Web/Assets/images/riko.png`.

## Verification

1. `cd Web && swift run WebConference`.
2. Confirm generated output:
   - `Web/Build/index.html` → maintenance page (centered Riko + "We'll be back soon.").
   - `Web/Build/2026/index.html` and `Web/Build/2026/en/index.html` → former conference home.
   - Past years (`Web/Build/2025/...` etc.), `/faq`, `/code-of-conduct`, `/privacy-policy`, `/booth-map` still generated at their existing paths.
3. Open `Web/Build/index.html` in a browser: verify vertical/horizontal centering and Riko rendering.
4. Spot-check that nav/footer "home" links on `/2026` and `/faq` point to `/2026`.

## Out of scope / non-goals

- No changes to the legacy top-level `Website/` directory.
- No changes to other pages' content.
- No bilingual maintenance copy (English only, by decision).
