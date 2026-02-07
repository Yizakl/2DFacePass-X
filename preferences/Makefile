ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = 2DFaceID-XPrefs

2DFaceID-XPrefs_FILES = Prefs.m
# 支持rootless和roothide越狱环境
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	2DFaceID-XPrefs_INSTALL_PATH = /var/jb/Library/PreferenceBundles
else
	2DFaceID-XPrefs_INSTALL_PATH = /Library/PreferenceBundles
endif
2DFaceID-XPrefs_FRAMEWORKS = UIKit
2DFaceID-XPrefs_PRIVATE_FRAMEWORKS = Preferences
2DFaceID-XPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	# 支持rootless和roothide越狱环境
	ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
		$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/var/jb/Library/PreferenceLoader/Preferences$(ECHO_END)
		$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/var/jb/Library/PreferenceLoader/Preferences/2DFaceID-XPrefs.plist$(ECHO_END)
	else
		$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
		$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/2DFaceID-XPrefs.plist$(ECHO_END)
	endif
