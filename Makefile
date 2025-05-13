ARCHS = arm64 arm64e
TARGET := iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirrorDisplay

AutoMirrorDisplay_FILES = Tweak.x
AutoMirrorDisplay_CFLAGS = -fobjc-arc
AutoMirrorDisplay_FRAMEWORKS = UIKit Foundation CoreGraphics
AutoMirrorDisplay_LIBRARIES = substrate
AutoMirrorDisplay_LDFLAGS = -F$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/PrivateFrameworks
AutoMirrorDisplay_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += AutoMirrorPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
