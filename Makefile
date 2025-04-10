ARCHS = arm64e
TARGET = iphone:clang:latest:16.5

INSTALL_TARGET_PROCESSES = SpringBoard

export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoMirrorDisplay
AutoMirrorDisplay_FILES = Tweak.swift
AutoMirrorDisplay_CFLAGS = -fobjc-arc
AutoMirrorDisplay_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
