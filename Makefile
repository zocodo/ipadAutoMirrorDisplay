ARCHS = arm64 arm64e
TARGET := iphone:clang:16.5:14.0

# RootHide 支持
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirrorDisplay

AutoMirrorDisplay_FILES = Tweak.x
AutoMirrorDisplay_CFLAGS = -fobjc-arc
AutoMirrorDisplay_FRAMEWORKS = UIKit Foundation CoreGraphics
AutoMirrorDisplay_LDFLAGS = -F$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/PrivateFrameworks
AutoMirrorDisplay_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += AutoMirrorPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
