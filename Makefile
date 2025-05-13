ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirrorDisplay

AutoMirrorDisplay_FILES = Tweak.x
AutoMirrorDisplay_CFLAGS = -fobjc-arc
AutoMirrorDisplay_FRAMEWORKS = UIKit Foundation
AutoMirrorDisplay_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += AutoMirrorPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
