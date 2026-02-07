include $(THEOS)/makefiles/common.mk

# Set target iOS version
TARGET = iphone:16.5:15.0

TWEAK_NAME = 2DFaceX

2DFaceX_FILES = Tweak/Tweak.xm Tweak/FaceRecognizer.m Tweak/FaceDatabase.m
2DFaceX_FRAMEWORKS = UIKit AVFoundation CoreMedia CoreVideo CoreImage Vision
2DFaceX_PRIVATE_FRAMEWORKS = SpringBoardServices
2DFaceX_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I$(SRCROOT)/Include
2DFaceX_LDFLAGS = -lobjc
2DFaceX_ARCHS = arm64

# Rootless support
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
2DFaceX_INSTALL_PATH = /var/jb/Library/MobileSubstrate/DynamicLibraries/
else
2DFaceX_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/
endif

# Ensure compatibility with roothide
# Let Theos handle the package scheme automatically

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
