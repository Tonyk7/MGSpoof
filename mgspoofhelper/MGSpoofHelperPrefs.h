#import <objc/runtime.h>

typedef enum {
	kAdd,
	kRemove,
	kExists
} prefActions;

@interface MGSpoofHelperPrefs : NSObject
+(BOOL)handleAppPrefsWithAction:(int)action inKey:(NSString *)key withValue:(id)value;
+(id)retrieveObjectFromKey:(NSString *)key;
+(void)addToKey:(NSString *)key withValue:(id)value inDictKey:(NSString *)dictKey;
+(void)removeKey:(NSString *)key inDictKey:(NSString *)dictKey;
@end