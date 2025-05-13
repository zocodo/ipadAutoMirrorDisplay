ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AutoMirrorPrefs

AutoMirrorPrefs_FILES = AutoMirrorPrefs.m
AutoMirrorPrefs_FRAMEWORKS = UIKit
AutoMirrorPrefs_PRIVATE_FRAMEWORKS = Preferences
AutoMirrorPrefs_INSTALL_PATH = /Library/PreferenceBundles
AutoMirrorPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp Resources/Preferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AutoMirrorPrefs.plist$(ECHO_END) 