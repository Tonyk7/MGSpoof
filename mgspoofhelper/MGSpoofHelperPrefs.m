#import <notify.h>
#import "MGSpoofHelperPrefs.h"

@implementation MGSpoofHelperPrefs

+(BOOL)handleAppPrefsWithAction:(int)action inKey:(NSString *)key withValue:(id)value {
	NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tonyk7.MGSpoofHelperPrefsSuite"];
	NSArray *oldArray = (NSArray *)[userDefaults objectForKey:key];
	// if there is no array make it 
	if (!oldArray) {
		[userDefaults setValue:@[] forKey:key];
		oldArray = @[];
	}
	NSMutableArray *tempArray = oldArray.mutableCopy;
	// add or remove item from remove and update array in userDefaults depending on action
	switch (action) {
		case kAdd:
			if ([value isKindOfClass:[NSString class]]) {
				if (value && ![tempArray containsObject:value])
					[tempArray addObject:value];
			} else if (value && [value isKindOfClass:[NSArray class]]) {
					tempArray = [tempArray arrayByAddingObjectsFromArray:value].mutableCopy;
			}
			break;
		case kRemove:
			if (value && [tempArray containsObject:value])
				[tempArray removeObject:value];
			break;
		case kExists:
			return [tempArray containsObject:value];
	}
	// update the array in userDefaults
	[userDefaults setValue:tempArray forKey:key];
	notify_post("com.tonyk7.mgspoof/appsChosenUpdated");
	return 0;
}

+(void)addToKey:(NSString *)key withValue:(id)value inDictKey:(NSString *)dictKey {
	NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tonyk7.MGSpoofHelperPrefsSuite"];
	NSMutableDictionary *newDict = ((NSDictionary *)[userDefaults objectForKey:dictKey]).mutableCopy;
	if (!newDict) {
		[userDefaults setValue:@{} forKey:dictKey];
		newDict = @{}.mutableCopy;
	}
	newDict[key] = value;
	[userDefaults setValue:newDict forKey:dictKey];
	notify_post("com.tonyk7.mgspoof/modifiedKeyUpdated");
}

+(void)removeKey:(NSString *)key inDictKey:(NSString *)dictKey {
	NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tonyk7.MGSpoofHelperPrefsSuite"];
	NSMutableDictionary *newDict = ((NSDictionary *)[userDefaults objectForKey:dictKey]).mutableCopy;
	[newDict removeObjectForKey:key];
	[userDefaults setValue:newDict forKey:dictKey];
	notify_post("com.tonyk7.mgspoof/modifiedKeyUpdated");
}

+(id)retrieveObjectFromKey:(NSString *)key {
	NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tonyk7.MGSpoofHelperPrefsSuite"];
	return [userDefaults objectForKey:key];
}

@end