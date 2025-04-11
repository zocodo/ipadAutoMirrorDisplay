TARGET := iphone:clang:latest:16.5.1
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirror

AutoMirror_FILES = $(shell find Sources/AutoMirror -name '*.swift') $(shell find Sources/AutoMirrorC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
AutoMirror_SWIFTFLAGS = -ISources/AutoMirrorC/include
AutoMirror_CFLAGS = -fobjc-arc -ISources/AutoMirrorC/include

include $(THEOS_MAKE_PATH)/tweak.mk
