#import "MGAppPickerController.h"
#import "MGSpoofHelperPrefs.h"

CFPropertyListRef MGCopyAnswer(CFStringRef);

@interface UIImage (MGSpoofHelper)
+(UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)arg1 format:(int)arg2 scale:(float)arg3;
+(UIImage *)imageNamed:(NSString *)arg1 inBundle:(NSBundle *)arg2;
@end

@interface LSApplicationWorkspace : NSObject
+(id)defaultWorkspace;
-(NSArray *)allInstalledApplications;
@end

@interface LSResourceProxy : NSObject
@property (nonatomic, readonly) NSDictionary *iconsDictionary;
@property (nonatomic, copy) NSArray *_boundIconFileNames; // iOS 11 and up
@property (nonatomic, copy) NSArray *boundIconFileNames; // iOS 10 and below
@end

@interface LSApplicationProxy : LSResourceProxy
+(LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)arg1;
@property (nonatomic, readonly) NSString *applicationIdentifier; // bundle id
@property (nonatomic, readonly) NSString *applicationType; // system app or user app
@property(nonatomic, readonly) NSArray *appTags;
-(NSString *)localizedName; // app name under icon
@end
 
@implementation MGAppPickerController

// Instead of using ipc to interact with springboard and get information and use SBApplicationController to do this, decided to get info using MobileCoreServices framework
-(NSArray *)apps {
	NSMutableArray *allInstalledApplications = [[objc_getClass("LSApplicationWorkspace") defaultWorkspace] allInstalledApplications].mutableCopy;
	// add springboard so user can spoof stuff in springboard
	[allInstalledApplications addObject:[objc_getClass("LSApplicationProxy") applicationProxyForIdentifier:@"com.apple.springboard"]];
	return allInstalledApplications;
}

-(NSDictionary *)appsDict {
	NSMutableDictionary *visibleApps = [[NSMutableDictionary alloc] init];
	NSArray *allApps = [self apps];
	for (LSApplicationProxy *app in allApps) {
		visibleApps[app.applicationIdentifier] = app.localizedName;
	}
	return visibleApps;
}

-(NSArray *)sortArray:(NSArray *)arrayToSort {
	return [arrayToSort sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

// first element is array of sorted user apps bundle ids, second element is same with system apps instead
-(NSArray *)splitAppTypes {
	NSMutableArray *systemApps = @[].mutableCopy;
	NSMutableArray *userApps = @[].mutableCopy;
	for (LSApplicationProxy *app in [self apps]) {
		if ([self hasIconAndVisible:app]){
			if ([app.applicationType isEqualToString:@"User"])
				[userApps addObject:app.applicationIdentifier];
			else if ([app.applicationType isEqualToString:@"System"])
				[systemApps addObject:app.applicationIdentifier];
		}
	}
	return @[[self sortArray:userApps], [self sortArray:systemApps]];
}

/// Method to check if app is hidden taken from KBAppList here: https://github.com/kanesbetas/KBAppList/blob/8653e1ee511639d341380b603e98b4cbce556dfb/Source/kbapplist/KBAppList.mm#L109-L118
-(BOOL)hasIconAndVisible:(LSApplicationProxy *)app {
	// so mgspoofhelper doesn't show up in list
	if ([app.applicationIdentifier isEqualToString:@"com.tonyk7.mgspoofhelper"])
		return NO;
	BOOL iOS11AndPlus = kCFCoreFoundationVersionNumber > 1400;
	NSArray *iconNames = iOS11AndPlus ? app._boundIconFileNames : app.boundIconFileNames;
	// springboard type is "Hidden" so allow it if it's springboard regardless of type
	if ((app.iconsDictionary || iconNames) && (![app.appTags containsObject:@"hidden"] || [app.applicationIdentifier isEqualToString:@"com.apple.springboard"]))
		return YES;
	return NO;
}

-(void)loadView {
	[super loadView];
	self.tableView.dataSource = self;
	self.tableView.allowsSelection = NO;
	
	self.navigationItem.title = @"Select apps";

	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
	self.navigationItem.leftBarButtonItem = backButton;
	UIBarButtonItem *resetPrefsButton = [[UIBarButtonItem alloc] initWithTitle:@"Reset Prefs" style:UIBarButtonItemStyleDone target:self action:@selector(resetPrefs)];
	self.navigationItem.rightBarButtonItem = resetPrefsButton;

	self.applications = [self appsDict];
	self.appTypes = [self splitAppTypes];
}

-(void)back {
	[self dismissViewControllerAnimated:YES completion:nil];
}

-(void)resetPrefs {
	NSUserDefaults *userDeafaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tonyk7.MGSpoofHelperPrefsSuite"];
	// [userDeafaults removePersistentDomainForName:[NSBundle mainBundle].bundleIdentifier];
	NSDictionary *defaultsDictionary = [userDeafaults dictionaryRepresentation];
	for (NSString *key in defaultsDictionary.allKeys) {
		[userDeafaults removeObjectForKey:key];
	}
	[self.tableView reloadData]; // turn off all switches
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"User apps";
		case 1:
			return @"System apps";
		default:
			return @"Other";
	}
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.appTypes[section].count;
}

-(void)fixImageView:(UIImageView *)imageView {
	/* bad way to do this */
	// resize image
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(29, 29), NO, 0.0);
	[imageView.image drawInRect:CGRectMake(0, 0, 29, 29)];
	UIImage *fixedImage = UIGraphicsGetImageFromCurrentImageContext();    
	UIGraphicsEndImageContext();
	imageView.image = fixedImage;
	// mask imageview
	CALayer *mask = [CALayer layer];
	NSBundle *mobileIcons = [NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"];
	mask.contents = (id)[UIImage imageNamed:@"AppIconMask" inBundle:mobileIcons].CGImage;
	mask.frame = CGRectMake(0, 0, 29, 29);
	imageView.layer.mask = mask;
	imageView.layer.masksToBounds = YES;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = [NSString stringWithFormat:@"AppPickerCellC%ldR%ld", indexPath.section, indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}

	UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	[cellSwitch addTarget:self action:@selector(updateSwitch:) forControlEvents:UIControlEventTouchUpInside];
	cellSwitch.tag = indexPath.row;
	cell.accessoryView = cellSwitch;

	NSString *bundleID = self.appTypes[indexPath.section][indexPath.row];
	cell.textLabel.text = self.applications[bundleID];
	cell.detailTextLabel.text = bundleID;

	UIImage *image = [UIImage _applicationIconImageForBundleIdentifier:bundleID format:0 scale:[UIScreen mainScreen].scale];
	if (CGSizeEqualToSize(image.size, CGSizeMake(29, 29))) 
		cell.imageView.image = image;
	else {
		// bad way to do this but whatever
		cell.imageView.image = [UIImage _applicationIconImageForBundleIdentifier:bundleID format:10 scale:0];
		[self fixImageView:cell.imageView];
	}

	// make uiswitch on if it should be enabled
	if ([objc_getClass("MGSpoofHelperPrefs") handleAppPrefsWithAction:kExists inKey:@"spoofApps" withValue:bundleID])
		[cellSwitch setOn:YES animated:NO];

	return cell;
}

-(void)updateSwitch:(UISwitch *)updatedSwitch {
	UITableViewCell *cell = (UITableViewCell *)updatedSwitch.superview;
	NSString *bundleID = cell.detailTextLabel.text;
	if (updatedSwitch.isOn)
		[objc_getClass("MGSpoofHelperPrefs") handleAppPrefsWithAction:kAdd inKey:@"spoofApps" withValue:bundleID];
	else
		[objc_getClass("MGSpoofHelperPrefs") handleAppPrefsWithAction:kRemove inKey:@"spoofApps" withValue:bundleID];
}

@end
