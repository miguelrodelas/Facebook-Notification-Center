//
//  AppDelegate.h
//  fbNotifications
//
//  Created by Miguel on 8/9/12.
//  Copyright (c) 2012 Miguel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PhFacebook/PhFacebook.h>

@interface AppDelegate : NSObject <NSApplicationDelegate ,PhFacebookDelegate, NSUserNotificationCenterDelegate>

// Before Login View
@property (weak) IBOutlet NSView *beforeLoginView;
@property (weak) IBOutlet NSButton *loginButton;
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;

// After Login View
@property (weak) IBOutlet NSView *afterLoginView;
@property (weak) IBOutlet NSTextField *minutesToCheck;
@property (weak) IBOutlet NSTextField *userName;
@property (weak) IBOutlet NSImageView *userImage;
@property (weak) IBOutlet NSButton *openAtLoginCheckbox;

@property (assign) IBOutlet NSWindow *window;


// Login to Facebook Button
- (IBAction)login:(id)sender;

// Quit the App
- (IBAction)quit:(id)sender;

// Settings - the user changed the minutes to check for notifications
- (IBAction)minutesToCheckChanged:(id)sender;

// Settings - Open at login checkbox
- (IBAction)openAtLoginToggle:(id)sender;

@end
