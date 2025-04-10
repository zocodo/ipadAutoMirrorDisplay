ARCHS = arm64
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME = rootless
PACKAGE_VERSION = 1.0.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirrorDisplay

AutoMirrorDisplay_FILES = Tweak/Tweak.x
AutoMirrorDisplay_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk