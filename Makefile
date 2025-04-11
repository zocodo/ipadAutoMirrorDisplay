export TARGET = iphone:clang:latest:16.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iPadDisplayMode
iPadDisplayMode_FILES = Tweak.xm
iPadDisplayMode_FRAMEWORKS = UIKit
iPadDisplayMode_PRIVATE_FRAMEWORKS = ControlCenterUIKit SpringBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk
