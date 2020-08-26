#import "MGSpoofHelperRootViewController.h"
#import "MGSpoofHelperAppDelegate.h"
#import "MGSpoofHelperPrefs.h"
#import "MGKeyPickerController.h"
#import "MGAppPickerController.h"

CFPropertyListRef MGCopyAnswer(CFStringRef);

#define mgValue(key) (__bridge NSString *)MGCopyAnswer((__bridge CFStringRef)key)
#define CGRectSetWidth(rect, width) CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height);
#define CGRectSetXY(rect, x, y) CGRectMake(x, y, rect.size.width, rect.size.height)
#define kMgValueLabelTag 787878 // "xxx" in hex :)
#define kMgValueLabelInset 5

@implementation MGSpoofHelperRootViewController

-(void)loadView {
	[super loadView];

	[self updateKeysArray];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;

	self.title = @"MGSpoofer";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addKeys)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Apps" style:UIBarButtonItemStyleDone target:self action:@selector(selectApps)];

	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRoated) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)deviceRoated {
	[self.tableView reloadData];
}

-(void)updateKeysArray {
	mgKeysToModify = ((NSArray *)[objc_getClass("MGSpoofHelperPrefs") retrieveObjectFromKey:@"keysChosen"]).mutableCopy;
}

-(void)selectApps {
	MGAppPickerController *appPicker = [[MGAppPickerController alloc] init];
	UINavigationController *navAppPicker = [[UINavigationController alloc] initWithRootViewController:appPicker];
	[self presentViewController:navAppPicker animated:YES completion:nil];
}

-(void)addKeys {
	MGKeyPickerController *keyPicker = [[MGKeyPickerController alloc] init];
	UINavigationController *navKeyPicker = [[UINavigationController alloc] initWithRootViewController:keyPicker];
	[self presentViewController:navKeyPicker animated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateKeysArray];
	[self.tableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([mgKeysToModify count] > 0) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		self.tableView.backgroundView = nil;
		return 1;
	}
	else {
		UILabel *noKeysChosenLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
		noKeysChosenLabel.text = @"Choose key(s) to modify";
		noKeysChosenLabel.textColor = [UIColor blackColor];
		noKeysChosenLabel.textAlignment = NSTextAlignmentCenter;
		self.tableView.backgroundView = noKeysChosenLabel;
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		return 0;
	}
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return mgKeysToModify.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = [NSString stringWithFormat:@"ModifyPickerCellR%ld", (long)indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}

	NSString *mgKey = mgKeysToModify[indexPath.row];
	cell.textLabel.text = mgKey;
	NSDictionary *modifiedKeys = [objc_getClass("MGSpoofHelperPrefs") retrieveObjectFromKey:@"modifiedKeys"];

	// if we have a modified one in prefs, display that value of default one
	id value = modifiedKeys[mgKey] ?: mgValue(mgKey);
	NSString *valueString = [value description] ?: nil;

	if (valueString) {
		UILabel *mgValueLabel;
		if (![cell viewWithTag:kMgValueLabelTag]) {
			mgValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			mgValueLabel.tag = kMgValueLabelTag;
		} else
			mgValueLabel = (UILabel *)[cell viewWithTag:kMgValueLabelTag];

		mgValueLabel.text = valueString;
		[mgValueLabel sizeToFit];
		CGFloat cellWidth = [UIScreen mainScreen].bounds.size.width;
		if (mgValueLabel.bounds.size.width >= cellWidth/2) {
			// change width of label to two thirds of a cell
			mgValueLabel.frame = CGRectSetWidth(mgValueLabel.frame, cellWidth*2/3);
			mgValueLabel.adjustsFontSizeToFitWidth = YES;
		}
		CGFloat x = cellWidth - mgValueLabel.bounds.size.width - kMgValueLabelInset;
		CGFloat y = tableView.rowHeight + mgValueLabel.bounds.size.height*2 - kMgValueLabelInset;
		mgValueLabel.frame = CGRectSetXY(mgValueLabel.frame, x, y);
		[cell addSubview:mgValueLabel];
	}
	return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	[objc_getClass("MGSpoofHelperPrefs") handleAppPrefsWithAction:kRemove inKey:@"keysChosen" withValue:mgKeysToModify[indexPath.row]];
	[objc_getClass("MGSpoofHelperPrefs") removeKey:mgKeysToModify[indexPath.row] inDictKey:@"modifiedKeys"];
	[mgKeysToModify removeObjectAtIndex:indexPath.row];
	if ([tableView numberOfRowsInSection:[indexPath section]] == 1)
		[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
	else
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSString *mgKey = mgKeysToModify[indexPath.row];

	UIAlertController *setValueAlertController = [UIAlertController alertControllerWithTitle:mgKey message:[NSString stringWithFormat:@"Original value: %@", mgValue(mgKey)] preferredStyle:UIAlertControllerStyleAlert];
	[setValueAlertController addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
		textField.placeholder = @"New value";
		BOOL shouldUseNumbePad = [mgValue(mgKey) isKindOfClass:[NSNumber class]];
		if (shouldUseNumbePad)
			textField.keyboardType = UIKeyboardTypeNumberPad;
		[textField addTarget:self action:@selector(userEditedTextfield:) forControlEvents:UIControlEventEditingChanged];
	}];
	UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NSNumber *numberForm;
		NSString *textInput = [setValueAlertController textFields][0].text;
		if ([textInput isKindOfClass:[NSNumber class]])
			numberForm = @([textInput integerValue]);
		[objc_getClass("MGSpoofHelperPrefs") addToKey:mgKey withValue:(numberForm ?: textInput) inDictKey:@"modifiedKeys"];
		[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}];
	UIAlertAction *randomizeAction = [UIAlertAction actionWithTitle:@"Randomize" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		int lengthNeeded = [mgValue(mgKey) description].length;
		if ([mgValue(mgKey) isKindOfClass:[NSNumber class]]) {
			// randomize number
			NSMutableString *randomNumberString = [NSMutableString stringWithCapacity:lengthNeeded];
			// make sure first number not 0
			[randomNumberString appendString:@(arc4random_uniform(9)+1).stringValue];
			for (int idx = 1; idx < lengthNeeded; idx++) {
				[randomNumberString appendString:@(arc4random_uniform(10)).stringValue];
			}
			[objc_getClass("MGSpoofHelperPrefs") addToKey:mgKey withValue:@(randomNumberString.longLongValue) inDictKey:@"modifiedKeys"];
		}
		else {
			// generates random string following same format as original (cap sensitive, numbers where they need to be, etc..)
			NSMutableString *randomString = [NSMutableString stringWithCapacity:lengthNeeded];
			NSString *value = [mgValue(mgKey) description];
			for (int idx = 0; idx < lengthNeeded; idx++) {
				unichar character = [value characterAtIndex:idx];
				// for mac address
				if (character == 58) { // 58 = ":"
					[randomString appendString:@":"];
					continue;
				}
				if (isdigit(character))
					[randomString appendString:@(arc4random_uniform(10)).stringValue];
				else {
					if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character])
						[randomString appendFormat:@"%c", (unichar)('A' + arc4random_uniform(26))];
					else
						[randomString appendFormat:@"%c", (unichar)('a' + arc4random_uniform(26))];
				}
			}
			[objc_getClass("MGSpoofHelperPrefs") addToKey:mgKey withValue:randomString inDictKey:@"modifiedKeys"];
		}
		[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	confirmAction.enabled = NO;
	[setValueAlertController addAction:randomizeAction];
	[setValueAlertController addAction:confirmAction];
	[setValueAlertController addAction:cancelAction];
	[self presentViewController:setValueAlertController animated:YES completion:nil];
}

-(void)userEditedTextfield:(UITextField *)textField {
	UIAlertController *setValueAlertController = (UIAlertController *)self.presentedViewController;
	BOOL hasValue = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0;
	if (setValueAlertController) {
		UIAlertAction *okAction = setValueAlertController.actions[1]; // confirm button
		okAction.enabled = hasValue;
	}
}

@end
