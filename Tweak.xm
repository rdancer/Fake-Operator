/***
 * Fake Operator
 * Thanks to DarkMalloc
 * NSPwn (c) 2010
 **/
#import "AppSupport/CPDistributedMessagingCenter.h"

@class CPDistributedMessagingCenter;

static CPDistributedMessagingCenter *MainMessagingCenter;
static NSString *settingsFile = @"/var/mobile/Library/Preferences/com.nspwn.fakeoperatorpreferences.plist";

%hook SBTelephonyManager
- (id)init {

	// Center name must be unique, recommend using application identifier.
	MainMessagingCenter = [NSClassFromString(@"CPDistributedMessagingCenter") centerNamed:@"com.nspwn.fakeoperator"];
	[MainMessagingCenter runServerOnCurrentThread];

	// Register Messages
	[MainMessagingCenter registerForMessageName:@"operatorChanged" target:self selector:@selector(operatorChanged)];

	%orig;

}

%new
- (void)operatorChanged {
	NSDictionary *carrier = [NSDictionary dictionaryWithContentsOfFile:settingsFile];
	NSString *carrierString = [carrier objectForKey:@"FakeOperator"];
	id controller = [NSClassFromString(@"SBTelephonyManager") sharedTelephonyManager];
	[controller setOperatorName:[carrier objectForKey:@"FakeOperator"]];
	
	[carrier release];
}

- (void)setOperatorName:(id)arg1 {

	NSString *replacement = [[NSString alloc] initWithString:arg1];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:settingsFile]) {
	
		NSDictionary *carrier = [[NSDictionary dictionaryWithContentsOfFile:settingsFile] retain];
		NSLog(@"Carrier: %@", carrier);
		
		if ([[carrier objectForKey:@"Enabled"] boolValue]) {
			
			NSLog(@"com.nspwn.fakeoperator is enabled");
			NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsFile];
			
			if ([[carrier objectForKey:@"FakeCarrier"] isEqualToString:@""]) {
				
				//Resetting Carrier / Disable
				[replacement release];
				replacement = [carrier objectForKey:@"DefaultCarrier"];
				[plist setObject:[NSNumber numberWithBool:NO] forKey:@"Enabled"];
			} else {
			
				//Enable & Set DefaultCarrier (Backup)
				[plist setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
				[plist setObject:arg1 forKey:@"DefaultCarrier"];
				[replacement release];
				replacement = [carrier objectForKey:@"FakeCarrier"];
			}
			
			[plist writeToFile:settingsFile atomically:YES];
			[plist release];
		} else {
			
			NSLog(@"com.nspwn.fakeoperator is disabled");
		}
		[carrier release];
	}
	
	[settingsFile release];
	
	NSLog(@"com.nspwn.fakeoperator: %@", replacement);

	%orig(replacement);
}

%end