---
name: asc-submit
description: Build, archive, export, and upload the try! Swift Tokyo app to App Store Connect for iOS, macOS, and visionOS using ASC CLI.
---

# ASC CLI App Submission Guide

This skill covers building, archiving, exporting, and uploading the try! Swift Tokyo app to App Store Connect for all three platforms (iOS, macOS, visionOS).

## Prerequisites

- ASC CLI authenticated: `asc auth status` should show credentials
- Xcode with iOS, macOS, and visionOS SDKs installed
- `ExportOptions.plist` at project root (method: app-store-connect, teamID: 9PC9DZ9559)

## Project Info

- **App ID**: 6479317240
- **Bundle ID**: jp.tryswift.tokyo.App
- **Team ID**: 9PC9DZ9559
- **Workspace**: trySwiftTokyo.xcworkspace
- **Scheme**: App

## Build Number Strategy

All three platforms share `CURRENT_PROJECT_VERSION` in the Xcode project. When archiving, override via xcodebuild if needed:

```bash
xcodebuild ... CURRENT_PROJECT_VERSION=<number>
```

Query the highest existing build number across all platforms and use max + 1:

```bash
asc builds list --app 6479317240 --platform IOS --limit 1
asc builds list --app 6479317240 --platform MAC_OS --limit 1
asc builds list --app 6479317240 --platform VISION_OS --limit 1
```

## Archive Commands

IMPORTANT: Do NOT archive multiple platforms in parallel. They share the same DerivedData and the build database will lock, causing disk I/O errors. Always archive sequentially.

### iOS

```bash
xcodebuild clean archive \
  -workspace trySwiftTokyo.xcworkspace -scheme "App" \
  -configuration Release -archivePath /tmp/tryTokyo-iOS.xcarchive \
  -destination "generic/platform=iOS" -allowProvisioningUpdates
```

### macOS

```bash
xcodebuild clean archive \
  -workspace trySwiftTokyo.xcworkspace -scheme "App" \
  -configuration Release -archivePath /tmp/tryTokyo-macOS.xcarchive \
  -destination "generic/platform=macOS" -allowProvisioningUpdates
```

### visionOS

```bash
xcodebuild clean archive \
  -workspace trySwiftTokyo.xcworkspace -scheme "App" \
  -configuration Release -archivePath /tmp/tryTokyo-visionOS.xcarchive \
  -destination "generic/platform=xrOS" -allowProvisioningUpdates
```

## Export Commands

Export can run in parallel (no DerivedData conflict).

```bash
xcodebuild -exportArchive \
  -archivePath /tmp/tryTokyo-<platform>.xcarchive \
  -exportPath /tmp/tryTokyo-<platform>-export \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates
```

## Upload Commands

### iOS

```bash
asc builds upload --app 6479317240 \
  --ipa "/tmp/tryTokyo-iOS-export/try! Tokyo.ipa"
```

### macOS (requires --version and --build-number)

```bash
asc builds upload --app 6479317240 \
  --pkg "/tmp/tryTokyo-macOS-export/try! Tokyo.pkg" \
  --version "<VERSION>" --build-number "<BUILD>"
```

### visionOS (MUST specify --platform VISION_OS)

```bash
asc builds upload --app 6479317240 \
  --ipa "/tmp/tryTokyo-visionOS-export/try! Tokyo.ipa" \
  --platform VISION_OS
```

CRITICAL: Without `--platform VISION_OS`, the visionOS IPA is processed as iOS and will fail with platform validation errors (ITMS-90508, ITMS-90502, etc.).

## Post-Upload Verification

```bash
# Check processing state (should be VALID)
asc builds list --app 6479317240 --platform IOS --limit 1
asc builds list --app 6479317240 --platform MAC_OS --limit 1
asc builds list --app 6479317240 --platform VISION_OS --limit 1

# Preflight checks before submission
asc submit preflight --app 6479317240 --version "<VERSION>" --platform IOS
asc submit preflight --app 6479317240 --version "<VERSION>" --platform MAC_OS
asc submit preflight --app 6479317240 --version "<VERSION>" --platform VISION_OS
```

## Common Pitfalls

1. **Parallel archive fails**: Archives share DerivedData → disk I/O error. Always run sequentially.
2. **visionOS uploads as iOS**: Must pass `--platform VISION_OS` to `asc builds upload`.
3. **macOS PKG needs explicit version**: `--version` and `--build-number` are required for PKG uploads.
4. **Build number conflicts**: Query all 3 platforms before choosing a build number. Use the global max + 1.
5. **Export directory exists**: Remove the previous export directory before re-exporting (`rm -rf /tmp/tryTokyo-<platform>-export`).
