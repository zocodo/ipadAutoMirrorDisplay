TARGET = iphone:clang:latest:16.5
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ObcAutoMirror

ObcAutoMirror_FILES = Tweak.xm ObcAutoMirrorController.m
ObcAutoMirror_CFLAGS = -fobjc-arc
ObcAutoMirror_FRAMEWORKS = UIKit CoreGraphics
ObcAutoMirror_PRIVATE_FRAMEWORKS = DisplayServices SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk 