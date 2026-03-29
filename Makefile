format:
	@swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Android/ \
		./App/ \
		./DataClient/ \
		./iOS/ \
		./LocalizationGenerated/ \
		./Server/ \
		./Shared/ \
		./SharedModels/ \
		./Website/

android-build:
	cd Android && INCLUDE_SKIP=1 swift build

android-emulator:
	@if adb devices | grep -q 'emulator'; then \
		echo "Emulator already running"; \
	else \
		AVD=$$(emulator -list-avds | head -1); \
		if [ -z "$$AVD" ]; then echo "No AVD found. Create one in Android Studio." && exit 1; fi; \
		echo "Starting emulator: $$AVD"; \
		emulator -avd $$AVD & \
		adb wait-for-device; \
	fi

android-run: android-build android-emulator
	cd Android/.build/plugins/outputs/skipstone/AndroidApp/skipstone && ./gradlew installDebug
	adb shell am start -n tokyo.tryswift.android/.MainActivity
