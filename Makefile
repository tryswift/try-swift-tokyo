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
ANDROID_APP_ID = tokyo.tryswift.android
ANDROID_ACTIVITY = $(ANDROID_APP_ID)/.MainActivity

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

android-skipstone-setup:
	@rm -rf $(SKIPSTONE_DIR)/app
	@cp -R Android/app-wrapper $(SKIPSTONE_DIR)/app
	@chmod u+w $(SKIPSTONE_DIR)/settings.gradle.kts
	@grep -q 'include(":app")' $(SKIPSTONE_DIR)/settings.gradle.kts || \
		echo 'include(":app")' >> $(SKIPSTONE_DIR)/settings.gradle.kts
	@if [ ! -f $(SKIPSTONE_DIR)/local.properties ]; then \
		if [ -n "$$ANDROID_HOME" ]; then \
			echo "sdk.dir=$$ANDROID_HOME" > $(SKIPSTONE_DIR)/local.properties; \
		elif [ -n "$$ANDROID_SDK_ROOT" ]; then \
			echo "sdk.dir=$$ANDROID_SDK_ROOT" > $(SKIPSTONE_DIR)/local.properties; \
		elif [ -d "$$HOME/Library/Android/sdk" ]; then \
			echo "sdk.dir=$$HOME/Library/Android/sdk" > $(SKIPSTONE_DIR)/local.properties; \
		elif [ -d "$$HOME/Android/Sdk" ]; then \
			echo "sdk.dir=$$HOME/Android/Sdk" > $(SKIPSTONE_DIR)/local.properties; \
		else \
			echo "Error: Android SDK not found. Set ANDROID_HOME." >&2; exit 1; \
		fi; \
	fi

android-run: android-build android-emulator android-skipstone-setup
	cd $(SKIPSTONE_DIR) && gradle :app:installDebug
	adb shell am start -n $(ANDROID_ACTIVITY)

android-run-device: android-build android-skipstone-setup
	@DEVICE=$$(adb devices | grep -v emulator | grep 'device$$' | head -1 | cut -f1); \
	if [ -z "$$DEVICE" ]; then echo "No physical device found. Connect via USB or adb connect." && exit 1; fi; \
	echo "Installing to device: $$DEVICE"
	cd $(SKIPSTONE_DIR) && gradle :app:installDebug
	@DEVICE=$$(adb devices | grep -v emulator | grep 'device$$' | head -1 | cut -f1); \
	adb -s $$DEVICE shell am start -n $(ANDROID_ACTIVITY)
