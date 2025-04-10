ARCHS = arm64
TARGET = iphone:clang:latest:10.0
INSTALL_TARGET_PROCESSES = SpringBoard

export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirrorDisplay
AutoMirrorDisplay_FILES = Tweak.x
AutoMirrorDisplay_CFLAGS = -fobjc-arc
AutoMirrorDisplay_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
