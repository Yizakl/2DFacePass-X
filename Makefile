ARCHS = arm64 arm64e
# 使用iOS 16.0 SDK构建，支持iOS 14.0及以上版本，包括iOS 16.4.1
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 2DFaceID-X

2DFaceID-X_FILES = tweak/Tweak.xm tweak/FaceRecognition.m tweak/CameraManager.m tweak/UnlockManager.m
2DFaceID-X_CFLAGS = -fobjc-arc -I$(THEOS)/include
2DFaceID-X_LDFLAGS = -L$(THEOS)/lib -framework AVFoundation -framework CoreImage -framework CoreMedia -framework UIKit

# 支持rootless和roothide越狱环境
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	2DFaceID-X_INSTALL_PATH = /var/jb/Library/MobileSubstrate/DynamicLibraries
else
	2DFaceID-X_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
endif

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
