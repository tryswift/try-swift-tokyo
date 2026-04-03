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

SKIPSTONE_DIR = Android/.build/plugins/outputs/android/AndroidApp/destination/skipstone

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
		adb shell 'while [ "$$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'; \
	fi

android-run: android-build android-emulator
	@cp -R Android/app-wrapper $(SKIPSTONE_DIR)/app
	@chmod u+w $(SKIPSTONE_DIR)/settings.gradle.kts
	@grep -q 'include(":app")' $(SKIPSTONE_DIR)/settings.gradle.kts || \
		echo 'include(":app")' >> $(SKIPSTONE_DIR)/settings.gradle.kts
	@test -f $(SKIPSTONE_DIR)/local.properties || \
		echo "sdk.dir=$${ANDROID_HOME:-$$HOME/Library/Android/sdk}" > $(SKIPSTONE_DIR)/local.properties
	cd $(SKIPSTONE_DIR) && gradle :app:installDebug
	adb shell am start -n tokyo.tryswift.android/.MainActivity
