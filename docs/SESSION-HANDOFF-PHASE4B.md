# Session Handoff — Phase 4b (Skip Fuse migration, WIP)

This worktree (`.worktrees/phase4b-skip-fuse`, branch `phase4/skip-fuse-migration`)
holds the **first attempt** at switching the Android target from Skip Lite to
Skip Fuse. Phase 4a (PR #468 — Revert Phase 2) is **merged on `main`**, so the
codebase is back to a clean TCA + plain SwiftPM baseline. Phase 4b is **partially
in place** but `skip android build` is still failing because SharedModels (and
DataClient transitively) need their own Skip Fuse-flavored Package.swift, not
the Skip Lite-style INCLUDE_SKIP toggle they're running on.

## Where we landed

### Already done in this branch
- `Android/Package.swift`: replaced `skip-ui` / `skip-foundation` / `skip-model` deps with `skip-fuse-ui` and added `.package(path: "../Conference")` + `.package(path: "../DataClient")`.
- Re-renamed `Android/Sources/ScheduleFeature/` → `AndroidScheduleFeature/` and `LiveTranslationFeature/` → `AndroidLiveTranslationFeature/` to avoid SwiftPM target-name collisions with Conference.
- `Android/Sources/AndroidApp/TrySwiftTokyoApp.swift`: imports `ComposableArchitecture` + Conference's `SponsorFeature` and mounts a TCA `Store(initialState: SponsorsList.State()) { SponsorsList() }` directly into the Sponsor tab — **no SkipTCA bridge**.
- `Conference/Package.swift`: added `SponsorFeature` library product so Android can `.product(name: "SponsorFeature", package: "Conference")`.
- `Android/Sources/SponsorFeature/` deleted (Conference is the source of truth).

### Still failing
`skip android build` from `Android/` errors out on SharedModels with Skip Lite-flavored transpile errors (`Skip is unable to determine the owning type for member 'default'`). Root cause: SharedModels' Package.swift still uses the **Skip Lite INCLUDE_SKIP toggle** (skip-foundation / skip-model deps + skipstone plugin), which causes skipstone to engage Skip Lite mode for that target while AndroidApp is asking for Skip Fuse. Mixing modes inside the same package graph doesn't work.

I tried two intermediate states inside this branch — `skipstone + skip` only, then no Skip plugin at all — and both produced different failure modes (missing sourcehash inputs, then the Skip Lite transpile errors above). Neither is the right shape; SharedModels needs a true Skip Fuse Package.swift.

### Canonical Skip Fuse template (verified via `skip init`)

`skip init --native-model fuse-model-template FuseModel` produced:

```swift
// swift-tools-version: 6.1
import PackageDescription
let package = Package(
    name: "fuse-model-template",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FuseModel", type: .dynamic, targets: ["FuseModel"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.8.9"),
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "FuseModel", dependencies: [
            .product(name: "SkipFuse", package: "skip-fuse")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
```

`skip init --native-app fuse-app-template FuseApp` produced the same shape but with `skip-fuse-ui` / `SkipFuseUI` instead of `skip-fuse` / `SkipFuse`. Key invariants:
- `type: .dynamic` library product
- `skipstone` build plugin
- **Data-only / Model packages** → `skip-fuse` + `SkipFuse`
- **UI / App packages** → `skip-fuse-ui` + `SkipFuseUI`

These templates live at `/tmp/fuse-model-template/Package.swift` and `/tmp/fuse-app-template/Package.swift` after running `skip init` — useful reference for the resume work.

## Concrete next steps (resume here)

### Step 1 — SharedModels → Skip Fuse model package

Rewrite `SharedModels/Package.swift` to match the `skip init --native-model` template:
- Drop the old `INCLUDE_SKIP` toggle and Skip Lite deps.
- Add `.package(url: "https://source.skip.tools/skip.git", from: "1.8.9")` and `.package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.0")`.
- Library product: `name: "SharedModels", type: .dynamic, targets: ["SharedModels"]`.
- Target dep: `.product(name: "SkipFuse", package: "skip-fuse")`.
- Plugin: `.plugin(name: "skipstone", package: "skip")`.
- Keep `exclude: ["Skip"]` since the `Skip/skip.yml` directory under `Sources/SharedModels/Skip/` is still there and is read by skipstone for Skip Fuse too (verify by looking at the generated template — it doesn't include a `Skip/` dir but our existing one is harmless if `excluded`).

### Step 2 — DataClient → Skip Fuse model package

Same recipe as SharedModels. DataClient has `swift-dependencies` (TCA's DI lib) — that should be fine to keep. Drop the INCLUDE_SKIP-aware INCLUDE_SKIP toggle (already partly removed) and add `skip-fuse` + `SkipFuse` + skipstone plugin. The current `Client.swift` already has the `@DependencyClient` macro restored from the revert; it should compile under Skip Fuse via real Swift compilation.

### Step 3 — Conference target-by-target

Conference is the most invasive change. Each target that's transitively reached from `Android.AndroidApp → Conference.SponsorFeature` must be Skip Fuse-flavored: `SponsorFeature`, `DependencyExtra`, `SharedModels` (already covered in Step 1), `DataClient` (Step 2). For Phase 4 scope, only this transitive chain needs Skip Fuse plumbing. Other Conference targets (`AppFeature`, `GuidanceFeature`, `LiveTranslationFeature`, `MapKitClient`, `ScheduleFeature`, `VideoFeature`, `trySwiftFeature`, `Acknowledgements` if it lands) stay iOS-only and don't need any Skip plumbing.

Key detail: Conference is **also consumed by the iOS App via App.xcodeproj** — adding `skip-fuse` / `skip-fuse-ui` deps to Conference may bloat the iOS resolved graph. Verify after the change that iOS Xcode build still resolves cleanly (probably fine since these deps are no-ops on iOS hosts).

### Step 4 — Verify

```bash
cd Android
export ANDROID_NDK_HOME=~/Library/org.swift.swiftpm/swift-sdks/swift-6.3.1-RELEASE_android.artifactbundle/swift-android/android-ndk-r27d
skip android build           # expect Build complete!
skip android run             # expect emulator launch + Sponsors tab loads

cd ..
xcodebuild -workspace trySwiftTokyo.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipPackagePluginValidation build
make format
```

### Step 5 — CI workflow rewrite

`.github/workflows/build-android.yml` currently still has `INCLUDE_SKIP=1 swift build`. Replace with the Skip Fuse build:

```yaml
- name: Install Swift SDK for Android
  run: swift sdk install <official artifactbundle URL> --checksum <checksum>
- name: Setup Skip
  uses: skiptools/actions/setup-skip@v1
  with: { run-doctor: 'false' }
- name: Build (Skip Fuse)
  run: cd Android && skip android build
```

The exact `swift sdk install` URL/checksum needs to come from the Skip 1.8.9 release notes or `swift sdk list` output on a working machine.

### Step 6 — PR

Title: `Switch Android target to Skip Fuse and re-share SponsorFeature via Conference`. Use the plan body from `~/.claude/plans/ios-android-ios-android-swift-nifty-bumblebee.md` for the description.

## Known constraints discovered so far

1. `skip init`-generated templates use `swift-tools-version: 6.1` — our packages are 6.3, which should still work for Skip Fuse (Skip 1.8.9 ships against Swift 6.3.1).
2. `--bridge` flag on `skip android build` is on by default — that's the Kotlin bridging layer and is what we want.
3. `skip init` creates a `Sources/<Module>/Skip/skip.yml` (sometimes more files in `Skip/`); ours is empty, which is fine.
4. Mixing Skip Lite and Skip Fuse packages in the same graph = transpile errors. Whole graph must be Fuse-flavored.

## Don't-forget list before next push

- [ ] `phase4/skip-fuse-migration` is **already pushed** to origin as a WIP. No PR open yet — keep it local-only or open as draft once Step 4 verifies green.
- [ ] Don't delete `/tmp/fuse-model-template` or `/tmp/fuse-app-template` mid-investigation — they're the canonical reference templates.
- [ ] `d-date/skip-tca` 0.2.0 is published OSS but we no longer use it. Decision on archive vs maintain is out-of-scope for Phase 4.

## Update protocol

Append to this file under a `## Session — YYYY-MM-DD` heading instead of rewriting it. Move completed Steps to the top so next reader sees the trajectory.
