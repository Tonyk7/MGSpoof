include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MGSpoofHelper
MGSpoofHelper_FILES = $(wildcard *.m)
MGSpoofHelper_FRAMEWORKS = UIKit CoreGraphics
MGSpoofHelper_LIBRARIES = MobileGestalt
MGSpoofHelper_CFLAGS = -fobjc-arc
MGSpoofHelper_CODESIGN_FLAGS = -Sent.xml

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"MGSpoofHelper\"" || true
