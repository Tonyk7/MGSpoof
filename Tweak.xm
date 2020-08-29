#import <substrate.h>
#import <stdint.h>

static NSDictionary *modifiedKeys;
static NSArray *appsChosen;

// Our replaced version of MGCopyAnswer_internal
static CFPropertyListRef (*orig_MGCopyAnswer_internal)(CFStringRef property, uint32_t *outTypeCode);
CFPropertyListRef new_MGCopyAnswer_internal(CFStringRef property, uint32_t *outTypeCode) {
	if (modifiedKeys[(__bridge NSString *)property]) {
		return (__bridge_retained CFStringRef)modifiedKeys[(__bridge NSString *)property];
	}
	return orig_MGCopyAnswer_internal(property, outTypeCode);
}


static void appsChosenUpdated() {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.tonyk7.MGSpoofHelperPrefsSuite"];
	appsChosen = [prefs objectForKey:@"spoofApps"];
}

static void modifiedKeyUpdated() {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.tonyk7.MGSpoofHelperPrefsSuite"];
	modifiedKeys = [prefs objectForKey:@"modifiedKeys"];
}

%ctor {
	@autoreleasepool {
		appsChosenUpdated();
		// don't do anything if we in an app we don't want to spoof anything
		if (![appsChosen containsObject:[NSBundle mainBundle].bundleIdentifier])
			return;

		// basically dlopen libMobileGestalt
		MSImageRef libGestalt = MSGetImageByName("/usr/lib/libMobileGestalt.dylib");
		if (libGestalt) {
			// Get "_MGCopyAnswer" symbol
			void *MGCopyAnswerFn = MSFindSymbol(libGestalt, "_MGCopyAnswer");
			/*
			 * get address of MGCopyAnswer_internal by doing symbol + offset (should be 8 bytes)
			 * note: hex implementation of MGCopyAnswer: 01 00 80 d2 01 00 00 14 (from iOS 9+)
			 * so address of MGCopyAnswer + offset = MGCopyAnswer_internal. MGCopyAnswer_internal *always follows MGCopyAnswer (*from what I've checked)
			 */
			MSHookFunction(((void *)((const uint8_t *)MGCopyAnswerFn + 8)), (void *)new_MGCopyAnswer_internal, (void **)&orig_MGCopyAnswer_internal);
		}
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)appsChosenUpdated, CFSTR("com.tonyk7.mgspoof/appsChosenUpdated"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)modifiedKeyUpdated, CFSTR("com.tonyk7.mgspoof/modifiedKeyUpdated"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		modifiedKeyUpdated();
	}
}
