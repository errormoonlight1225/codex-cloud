TARGET := iphone:clang:16.5:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DamaiPocketTweak
DamaiPocketTweak_FILES = Tweak.xm
DamaiPocketTweak_CFLAGS = -fobjc-arc
DamaiPocketTweak_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
