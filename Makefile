TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = auto-display-mirror-mode

auto-display-mirror-mode_FILES = Tweak.x
auto-display-mirror-mode_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
