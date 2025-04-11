export TARGET = iphone:clang:latest:16.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iPadDisplayMode
iPadDisplayMode_FILES = Tweak.xm

# Public UIKit
iPadDisplayMode_FRAMEWORKS = UIKit

# Private frameworks
iPadDisplayMode_PRIVATE_FRAMEWORKS = ControlCenterUIKit SpringBoardServices

# Tell the linker where to find private frameworks
iPadDisplayMode_LDFLAGS += -F/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/tweak.mk
