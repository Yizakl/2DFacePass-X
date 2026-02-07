include $(THEOS)/makefiles/common.mk

# Enable parallel build
THEOS_MAKE_PARALLEL = YES

# Set target iOS version
# Use iOS 15.0 as minimum target to avoid Vision framework API availability issues
TARGET = iphone:16.5:15.0

# Explicitly set iOS deployment target
IPHONEOS_DEPLOYMENT_TARGET = 15.0

TWEAK_NAME = 2DFaceX

2DFaceX_FILES = Tweak/Tweak.xm Tweak/FaceRecognizer.m Tweak/FaceDatabase.m
2DFaceX_FRAMEWORKS = UIKit AVFoundation CoreMedia CoreVideo CoreImage Vision
2DFaceX_PRIVATE_FRAMEWORKS = SpringBoardServices
2DFaceX_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -mios-version-min=15.0
2DFaceX_LDFLAGS = -lobjc
# Only use arm64 architecture to avoid arm64e warning
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
