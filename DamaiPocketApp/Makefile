TARGET := iphone:clang:16.5:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = DamaiPocket
DamaiPocket_FILES = main.m DPAppDelegate.m DPViewController.m
DamaiPocket_CFLAGS = -fobjc-arc
DamaiPocket_FRAMEWORKS = UIKit UserNotifications

include $(THEOS_MAKE_PATH)/application.mk
