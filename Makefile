ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirrorDisplay

AutoMirrorDisplay_FILES = Tweak.x
AutoMirrorDisplay_CFLAGS = -fobjc-arc \
    -I$(THEOS)/include \
    -I$(THEOS)/vendor/include \
    -I$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/Frameworks/UIKit.framework/Headers \
    -I$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/Frameworks/Foundation.framework/Headers
AutoMirrorDisplay_FRAMEWORKS = UIKit Foundation
AutoMirrorDisplay_PRIVATE_FRAMEWORKS = Preferences
AutoMirrorDisplay_LDFLAGS = -F$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/Frameworks

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += AutoMirrorPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
