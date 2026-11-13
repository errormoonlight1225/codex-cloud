TARGET := iphone:clang:16.5:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = DamaiPocket
DamaiPocket_FILES = main.m DPAppDelegate.m DPViewController.m
DamaiPocket_CFLAGS = -fobjc-arc
DamaiPocket_FRAMEWORKS = UIKit WebKit
DamaiPocket_RESOURCE_FILES = AppIcon-120.png AppIcon-152.png AppIcon-167.png AppIcon-180.png AppIcon-1024.png

include $(THEOS_MAKE_PATH)/application.mk
