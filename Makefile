.PHONY: format android-build android-emulator android-install android-run

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

ANDROID_DIR = Android
ANDROID_APP_ID = tokyo.tryswift.android
ANDROID_ACTIVITY = $(ANDROID_APP_ID)/.MainActivity
JAVA_HOME ?= $(shell if [ -d "$$HOME/.asdf/installs/java/temurin-25.0.2+10.0.LTS" ]; then echo "$$HOME/.asdf/installs/java/temurin-25.0.2+10.0.LTS"; else /usr/libexec/java_home 2>/dev/null; fi)

android-build:
	cd $(ANDROID_DIR) && swift build

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

android-install: android-build android-emulator
	cd $(ANDROID_DIR) && if [ -n "$(JAVA_HOME)" ]; then JAVA_HOME="$(JAVA_HOME)" ./gradlew app:installDebug; else ./gradlew app:installDebug; fi

android-run: android-install
	adb shell am start -n $(ANDROID_ACTIVITY)
