TARGET := iphone:clang:latest:16.5.1
INSTALL_TARGET_PROCESSES = SpringBoard

# 启用 Swift 支持
THEOS_USE_SWIFT = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirror

AutoMirror_FILES = $(shell find Sources/AutoMirror -name '*.swift') $(shell find Sources/AutoMirrorC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
AutoMirror_SWIFTFLAGS = -ISources/AutoMirrorC/include
AutoMirror_CFLAGS = -fobjc-arc -ISources/AutoMirrorC/include

# Swift 相关配置
AutoMirror_SWIFT_BRIDGING_HEADER = Sources/AutoMirror/AutoMirror-Bridging-Header.h
AutoMirror_SWIFT_MODULE_NAME = AutoMirror

include $(THEOS_MAKE_PATH)/tweak.mk
