//
//  AppDelegate.m
//  fbNotifications
//
//  Created by Miguel on 8/9/12.
//  Copyright (c) 2012 Miguel. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () {
    NSStatusItem *statusItem;           // Icon at the top-right corner
    NSImage *statusImage;               // Icon image
    
    int latestCount;                    // Latest notifications counts to compare with the current one
    int newNotifications;
    NSString *latestUpdateTime;         // Latest notification timestamp
    
    NSTimer *timer;                     // Timer to check for notifications
}

@property (retain) PhFacebook* fb;      // Facebook API library
@end


@implementation AppDelegate
@synthesize loginButton;
@synthesize loadingIndicator;
@synthesize beforeLoginView;
@synthesize afterLoginView;
@synthesize minutesToCheck;
@synthesize userName;
@synthesize userImage;
@synthesize openAtLoginCheckbox;
@synthesize fb;



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // Initializations
    latestUpdateTime = [[NSString alloc]init];
    self.fb = [[PhFacebook alloc] initWithApplicationID: @"YOUR APPLICATION ID HERE" delegate: self];
    [self.fb getAccessTokenForPermissions: [NSArray arrayWithObjects: @"manage_notifications", nil] cached: NO];

    
    // Add icon to the menu extras (top-right corner)
    statusImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fb_small_icon" ofType:@"png"]];
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setImage:statusImage];
    [statusItem setToolTip:@"Facebook Notifications"];
    [statusItem setAction:@selector(openPreferences)];
    [statusItem setTitle:@"0"];
    
}

// Open the preferences window and bring to front when the status item is clicked
- (void) openPreferences {
    [self.window makeKeyAndOrderFront:self];
    [self.window orderFrontRegardless];
}

// Login button when the session has expired
- (IBAction)login:(id)sender {
    self.loadingIndicator.hidden = NO;
//    [self.fb getAccessTokenForPermissions: [NSArray arrayWithObjects: @"manage_notifications", @"read_mailbox", @"read_requests", nil] cached: NO];
    [self.fb getAccessTokenForPermissions: [NSArray arrayWithObjects: @"manage_notifications", nil] cached: NO];
}

// Quit the App entirely
- (IBAction)quit:(id)sender {
    [NSApp terminate:self];
}

// Change the frequency the notifications are checked
- (IBAction)minutesToCheckChanged:(id)sender {
    
    // Invalidate the old timer
    [timer invalidate];
    
    // Get the value introduced by the user and create a new timer with the given interval
    NSInteger minutes = [self.minutesToCheck integerValue];
    if (minutes == 0) {
        minutes = 3;
        [self.minutesToCheck setIntegerValue:minutes];
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:minutes forKey:@"minutesToCheck"];
    timer = [NSTimer scheduledTimerWithTimeInterval:minutes*60 target:self selector:@selector(checkForNotification) userInfo:nil repeats:YES];
}

// "Open at login" checkbox to start the app at the beginning of the current user session
- (IBAction)openAtLoginToggle:(id)sender {
    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		if ([sender state] == NSOnState) {
            [userDefaults setBool:YES forKey:@"openAtLogin"];
            [self enableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
        } else {
            [userDefaults setBool:NO forKey:@"openAtLogin"];
            [self disableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
        }
			
	}
	CFRelease(loginItems);
}



- (void) checkForNotification {
    //    [fb sendRequest: @"me/inbox"];
    [fb sendRequest:@"me/notifications"];
    //    [fb sendRequest:@"me/friendrequests"];
}


#pragma mark PhFacebookDelegate methods
- (void) tokenResult: (NSDictionary*) result
{
    self.loadingIndicator.hidden = YES;
    
    
    if ([[result valueForKey: @"valid"] boolValue])
    {
        // Get user info (name and picture)
        self.beforeLoginView.hidden = YES;
        self.afterLoginView.hidden = NO;
        [self checkForNotification];
        [fb sendRequest: @"me/picture"];
        [fb sendRequest:@"me"];
        
        // Get the frequency to check the notifications
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger minutes = [userDefaults integerForKey:@"minutesToCheck"];
        if (minutes == 0) {
            minutes = 3;
        }
        [self.minutesToCheck setStringValue:[NSString stringWithFormat:@"%ld", minutes]];
        timer = [NSTimer scheduledTimerWithTimeInterval:minutes*60 target:self selector:@selector(checkForNotification) userInfo:nil repeats:YES];
        
        // Get the open at login preference
        if ([userDefaults boolForKey:@"openAtLogin"]) {
            [self.openAtLoginCheckbox setState:1];
        } else {
            [self.openAtLoginCheckbox setState:0];
        }
    }
}



- (void) requestResult: (NSDictionary*) result
{
    
    // Pass the JSON to a NSDictionary
    NSString *request = [result objectForKey: @"request"];
    NSString *jsonString = [result objectForKey: @"result"];
//    NSLog(@"json: %@", jsonString);
    NSData *dataURL =  [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:dataURL
                          options:(NSJSONReadingOptions)[NSNull null]
                          error:&error];

    
    // User info
    if ([request isEqualTo:@"me"]) {
        NSString *userNameString = [json objectForKey:@"name"];
        [self.userName setStringValue:[NSString stringWithFormat:@"Hi %@!", userNameString]];
    }
    
    // User picture
    if ([request isEqualTo: @"me/picture"])
    {
        NSImage *pic = [[NSImage alloc] initWithData: [result objectForKey: @"raw"]];
        self.userImage.image = pic;
    }
    
    // User notifications
    if ([request isEqual:@"me/notifications"]) {
        NSArray *data = [json objectForKey:@"data"];
        //    NSLog(@"json: %@", json);
        
        // If there are not new notifications, don't go on
        NSDictionary *summary = [json objectForKey:@"summary"];
        if (summary.count == 0) {
            latestCount = 0;
            [statusItem setTitle:@"0"];
            return;
        }
        
        if ([summary objectForKey:@"unseen_count"] != nil) {
            NSString *unseenCount = [summary objectForKey:@"unseen_count"];
            
            if (latestCount != [unseenCount intValue]) {
                newNotifications = [unseenCount intValue] - latestCount;
                latestCount = [unseenCount intValue];
            }
        }
        
        if ([summary objectForKey:@"updated_time"] != nil) {
            NSString *updateTime = [summary objectForKey:@"updated_time"];
            if ([latestUpdateTime isEqual:updateTime]) {
                return;
            } else {
                latestUpdateTime = updateTime;
            }
        }
        [statusItem setTitle:[NSString stringWithFormat:@"%ld", data.count]];
        
        
        for (int i=0;i<newNotifications;i++) {
            // Sometimes the unseen_count is 1, but the data array is null
            if (data.count <= i) {
                return;
            }
            NSDictionary *notificationJSON = [data objectAtIndex:i];
            NSString *notification_id = [notificationJSON objectForKey:@"id"];
            NSString *title = [notificationJSON objectForKey:@"title"];
            NSString *link = [notificationJSON objectForKey:@"link"];
//            NSString *message = [notificationJSON objectForKey:@"message"];
            NSDictionary *from = [notificationJSON objectForKey:@"from"];
            NSString *fromName = [from objectForKey:@"name"];
            
            // Notification
            NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
            userNotificationCenter.delegate = self;
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = fromName;
            //            notification.subtitle = fromName;
            notification.informativeText = title;
            notification.soundName = NSUserNotificationDefaultSoundName;
            
            NSDictionary *userInfoDic = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:link, notification_id, nil] forKeys:[NSArray arrayWithObjects:@"link", @"id", nil]];
            notification.userInfo = userInfoDic;
            
            [userNotificationCenter deliverNotification:notification];
        }
        
    }
    
}

#pragma mark - NSUserNotificationCenter delegate
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSString *link = [notification.userInfo objectForKey:@"link"];
    NSString *notification_id = [notification.userInfo objectForKey:@"id"];
    
    // When the notification is clicked in the Notification Center, the default browser is launched to open the link and the
    // notification is deleted
    NSURL *url = [ [ NSURL alloc ] initWithString: link];
    if( ![[NSWorkspace sharedWorkspace] openURL:url] )
        NSLog(@"Failed to open url: %@",[url description]);
    [fb sendRequest:[NSString stringWithFormat:@"%@?unread=false", notification_id] params:nil usePostRequest:YES];
    [center removeDeliveredNotification:notification];
    [statusItem setTitle:[NSString stringWithFormat:@"%d",(latestCount-1)]];
}

// Present the notification even when the app is frontmost
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void) willShowUINotification: (PhFacebook*) sender
{
    self.loadingIndicator.hidden = YES;
    self.loginButton.hidden = NO;
    [NSApp requestUserAttention: NSInformationalRequest];
}

#pragma mark - Open at login
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
	if (item)
		CFRelease(item);
}

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (__bridge NSArray *)loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
			}
			// Docs for LSSharedFileListItemResolve say we're responsible
			// for releasing the CFURLRef that is returned
			if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
}

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath {
	BOOL found = NO;
	UInt32 seedValue;
	CFURLRef thePath = NULL;
    
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (__bridge NSArray *)loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
				found = YES;
				break;
			}
            // Docs for LSSharedFileListItemResolve say we're responsible
            // for releasing the CFURLRef that is returned
            if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
    
	return found;
}

@end
