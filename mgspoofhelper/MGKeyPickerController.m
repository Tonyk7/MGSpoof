#import "MGKeyPickerController.h"
#import "MGSpoofHelperPrefs.h"

CFPropertyListRef MGCopyAnswer(CFStringRef);

@implementation MGKeyPickerController

-(void)loadView {
	[super loadView];

	self.tableView.allowsMultipleSelection = YES;

	self.navigationItem.title = @"Add key to modify";
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
	UIBarButtonItem *confirmAddButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(addKeysToModify)];

	self.navigationItem.leftBarButtonItem = backButton;
	self.navigationItem.rightBarButtonItem = confirmAddButton;
	self.navigationItem.rightBarButtonItem.enabled = NO;

	// lol
	allKeys = @[@[@"DiskUsage", @"ModelNumber", @"SIMTrayStatus", @"SerialNumber", @"MLBSerialNumber", @"UniqueDeviceID", @"UniqueDeviceIDData", @"UniqueChipID", @"InverseDeviceID", @"DiagData", @"DieId", @"CPUArchitecture", @"PartitionType", @"UserAssignedDeviceName"],@[@"BluetoothAddress"],@[@"RequiredBatteryLevelForSoftwareUpdate", @"BatteryIsFullyCharged", @"BatteryIsCharging", @"BatteryCurrentCapacity", @"ExternalPowerSourceConnected"],@[@"BasebandSerialNumber", @"BasebandCertId", @"BasebandChipId", @"BasebandFirmwareManifestData", @"BasebandFirmwareVersion", @"BasebandKeyHashInformation"],@[@"CarrierBundleInfoArray", @"CarrierInstallCapability", @"InternationalMobileEquipmentIdentity", @"MobileSubscriberCountryCode", @"MobileSubscriberNetworkCode"],@[@"ChipID", @"ComputerName", @"DeviceVariant", @"HWModelStr", @"BoardId", @"HardwarePlatform", @"DeviceName", @"DeviceColor", @"DeviceClassNumber", @"DeviceClass", @"BuildVersion", @"ProductName", @"ProductType", @"ProductVersion", @"FirmwareNonce", @"FirmwareVersion", @"FirmwarePreflightInfo", @"IntegratedCircuitCardIdentifier", @"AirplaneMode", @"AllowYouTube", @"AllowYouTubePlugin", @"MinimumSupportediTunesVersion", @"ProximitySensorCalibration", @"RegionCode", @"RegionInfo", @"RegulatoryIdentifiers", @"SBAllowSensitiveUI", @"SBCanForceDebuggingInfo", @"SDIOManufacturerTuple", @"SDIOProductInfo", @"ShouldHactivate", @"SigningFuse", @"SoftwareBehavior", @"SoftwareBundleVersion", @"SupportedDeviceFamilies", @"SupportedKeyboards", @"TotalSystemAvailable"],@[@"AllDeviceCapabilities", @"AppleInternalInstallCapability", @"ExternalChargeCapability", @"ForwardCameraCapability", @"PanoramaCameraCapability", @"RearCameraCapability", @"HasAllFeaturesCapability", @"HasBaseband", @"HasInternalSettingsBundle", @"HasSpringBoard", @"InternalBuild", @"IsSimulator", @"IsThereEnoughBatteryLevelForSoftwareUpdate", @"IsUIBuild"],@[@"RegionalBehaviorAll", @"RegionalBehaviorChinaBrick", @"RegionalBehaviorEUVolumeLimit", @"RegionalBehaviorGB18030", @"RegionalBehaviorGoogleMail", @"RegionalBehaviorNTSC", @"RegionalBehaviorNoPasscodeLocationTiles", @"RegionalBehaviorNoVOIP", @"RegionalBehaviorNoWiFi", @"RegionalBehaviorShutterClick", @"RegionalBehaviorVolumeLimit"],@[@"ActiveWirelessTechnology", @"WifiAddress", @"WifiAddressData", @"WifiVendor"],@[@"FaceTimeBitRate2G", @"FaceTimeBitRate3G", @"FaceTimeBitRateLTE", @"FaceTimeBitRateWiFi", @"FaceTimeDecodings", @"FaceTimeEncodings", @"FaceTimePreferredDecoding", @"FaceTimePreferredEncoding"],@[@"DeviceSupportsFaceTime", @"DeviceSupportsTethering", @"DeviceSupportsSimplisticRoadMesh", @"DeviceSupportsNavigation", @"DeviceSupportsLineIn", @"DeviceSupports9Pin", @"DeviceSupports720p", @"DeviceSupports4G", @"DeviceSupports3DMaps", @"DeviceSupports3DImagery", @"DeviceSupports1080p"]];
}

-(void)back {
	[self dismissViewControllerAnimated:YES completion:nil];
}

-(void)addKeysToModify {
	[objc_getClass("MGSpoofHelperPrefs") handleAppPrefsWithAction:kAdd inKey:@"keysChosen" withValue:selectedItems];
	[self back];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 9;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"Identifying Information";
		case 1:
			return @"Bluetooth Information";
		case 2:
			return @"Battery Information";
		case 3:
			return @"Baseband Information";
		case 4:
			return @"Telephony Information";
		case 5:
			return @"Device Information";
		case 6:
			return @"Capability Information";
		case 7:
			return @"Regional Behaviour";
		case 8:
			return @"Wireless Information";
		case 9:
			return @"FaceTime Information";
		default:
			return @"Other";
	}
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return allKeys[section].count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = [NSString stringWithFormat:@"ChoicePickerCellS%ldR%ld", (long)indexPath.section, (long)indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}

	NSString *mgKey = allKeys[indexPath.section][indexPath.row];

	// hide cell (we return before adding anything + give it a height of 0 in other method so not visible)
	if ([objc_getClass("MGSpoofHelperPrefs") handleAppPrefsWithAction:kExists inKey:@"keysChosen" withValue:mgKey]) {
		return cell;
	}

	cell.textLabel.text = mgKey;
	id mgValueResponse = (__bridge id)MGCopyAnswer((__bridge CFStringRef)mgKey);
	cell.detailTextLabel.text = [mgValueResponse description] ?: nil;

	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// hide cell
	if ([objc_getClass("MGSpoofHelperPrefs") handleAppPrefsWithAction:kExists inKey:@"keysChosen" withValue:allKeys[indexPath.section][indexPath.row]]) {
		return 0;
	}
	return tableView.rowHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!selectedItems)
		selectedItems = [NSMutableArray array];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	NSString *cellValue = cell.textLabel.text;

	if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
		// Deselect case
		cell.accessoryType = UITableViewCellAccessoryNone;
		// remove from selectedItems arrays if needed
		if ([selectedItems containsObject:cellValue])
			[selectedItems removeObject:cellValue];
		// toggle "Add" button if needed
		if (selectedItems.count <= 0)
			self.navigationItem.rightBarButtonItem.enabled = NO;
	} else {
		// Select case
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		// add to selectedItems arrays if needed
		if (![selectedItems containsObject:cellValue])
			[selectedItems addObject:cellValue];
		// toggle "Add" button if needed
		if (selectedItems.count > 0)
			self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}

@end
