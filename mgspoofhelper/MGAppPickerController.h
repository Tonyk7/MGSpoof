@interface MGAppPickerController : UITableViewController {
	NSArray<NSString *> *hiddenDisplayIdentifiers;
}
@property (nonatomic, retain) NSDictionary *applications;
@property (nonatomic, retain) NSArray<NSArray *> *appTypes;
@end
