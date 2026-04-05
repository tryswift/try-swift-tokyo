Build, export, and upload the try! Swift Tokyo app to App Store Connect for iOS, macOS, and visionOS.

Refer to the `asc-submit` skill (`.claude/skills/asc-submit/SKILL.md`) for platform-specific details and pitfalls.

## Steps

1. Verify ASC CLI authentication: `asc auth status`
2. Check current version and build number: `xcodebuild -showBuildSettings -workspace trySwiftTokyo.xcworkspace -scheme "App" -configuration Release 2>/dev/null | grep -E 'CURRENT_PROJECT_VERSION|MARKETING_VERSION'`
3. Query latest build numbers across all 3 platforms to determine next build number
4. Archive each platform **sequentially** (never in parallel — shared DerivedData causes lock errors):
   - iOS: `-destination "generic/platform=iOS"`
   - macOS: `-destination "generic/platform=macOS"`
   - visionOS: `-destination "generic/platform=xrOS"`
5. Export all 3 platforms (can run in parallel)
6. Upload:
   - iOS: `asc builds upload --app 6479317240 --ipa "..."`
   - macOS: `asc builds upload --app 6479317240 --pkg "..." --version "X.Y.Z" --build-number "N"`
   - visionOS: `asc builds upload --app 6479317240 --ipa "..." --platform VISION_OS`
7. Wait for processing and verify all builds reach `VALID` state
8. Run preflight checks: `asc submit preflight --app 6479317240 --version "X.Y.Z" --platform <PLATFORM>`
9. Report results
