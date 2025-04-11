export TARGET = iphone:clang:latest:16.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iPadDisplayMode
iPadDisplayMode_FILES = Tweak.xm

# 添加必要的框架
iPadDisplayMode_FRAMEWORKS = UIKit
iPadDisplayMode_PRIVATE_FRAMEWORKS = SpringBoardServices SpringBoardUI ControlCenterUIKit

# 添加必要的链接标志
iPadDisplayMode_CFLAGS = -fobjc-arc
iPadDisplayMode_LDFLAGS = -F$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/PrivateFrameworks -framework SpringBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk
