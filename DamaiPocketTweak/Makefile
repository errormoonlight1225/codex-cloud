TARGET := iphone:clang:16.5:14.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES := DMPortal

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := DamaiPocket
DamaiPocket_FILES := Tweak.xm
DamaiPocket_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
DamaiPocket_FRAMEWORKS := UIKit Foundation QuartzCore
DamaiPocket_LIBRARIES := substrate

include $(THEOS_MAKE_PATH)/tweak.mk
