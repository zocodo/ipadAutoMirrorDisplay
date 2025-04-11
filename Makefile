TARGET = iphone:clang:latest:16.5
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ObcAutoMirror

ObcAutoMirror_FILES = Tweak.xm ObcAutoMirrorController.m
ObcAutoMirror_CFLAGS = -fobjc-arc
ObcAutoMirror_FRAMEWORKS = UIKit CoreGraphics
ObcAutoMirror_PRIVATE_FRAMEWORKS = SpringBoard

# 添加 SpringBoard 框架的路径
ObcAutoMirror_EXTRA_FRAMEWORKS = -F$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/tweak.mk 