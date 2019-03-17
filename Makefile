include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MGSpoof
MGSpoof_FILES = Tweak.xm
MGSpoof_CFLAGS = -fobjc-arc
MGSpoof_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += mgspoofhelper
include $(THEOS_MAKE_PATH)/aggregate.mk
