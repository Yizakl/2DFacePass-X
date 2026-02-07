include $(THEOS)/makefiles/common.mk

# Set target iOS version
TARGET = iphone:16.5:15.0

# Enable parallel build
THEOS_MAKE_PARALLEL = YES

# Use modern build system
THEOS_LEAN_AND_MEAN = YES

TWEAK_NAME = 2DFaceX

# Source files
2DFaceX_FILES = Tweak/Tweak.xm Tweak/FaceRecognizer.m Tweak/FaceDatabase.m

# Frameworks
2DFaceX_FRAMEWORKS = UIKit AVFoundation CoreMedia CoreVideo CoreImage Vision
2DFaceX_PRIVATE_FRAMEWORKS = SpringBoardServices

# Compiler flags
2DFaceX_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
2DFaceX_LDFLAGS = -lobjc

# Architecture
2DFaceX_ARCHS = arm64

# Rootless support
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
2DFaceX_INSTALL_PATH = /var/jb/Library/MobileSubstrate/DynamicLibraries/
else
2DFaceX_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/
endif

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
