#import "MGSpoofHelperAppDelegate.h"
#import "MGSpoofHelperRootViewController.h"

@implementation MGSpoofHelperAppDelegate

-(void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[MGSpoofHelperRootViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
