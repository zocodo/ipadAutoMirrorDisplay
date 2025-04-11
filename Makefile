TARGET := iphone:clang:16.5:16.5
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ObcAutoMirror

ObcAutoMirror_FILES = Tweak.xm ObcAutoMirrorController.m
ObcAutoMirror_CFLAGS = -fobjc-arc
ObcAutoMirror_FRAMEWORKS = UIKit CoreGraphics
ObcAutoMirror_PRIVATE_FRAMEWORKS = DisplayServices

# 添加 SDK 路径设置
SDK_PATH = $(THEOS)/sdks/iPhoneOS16.5.sdk
SDKROOT = $(SDK_PATH)

include $(THEOS_MAKE_PATH)/tweak.mk 