//
//  OldStuff.h
//  MacNagios
//
//  Created by Kiko Albiol on 21/11/15.
//  Copyright © 2015 BGP. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  @brief  Old stuff
 */
@interface AppDelegateOld : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

@property (assign) IBOutlet NSWindow *window;
@property WebView *webView;
@property NSStatusItem *statusItem;
@property NSTimer *timer;
@property NSDictionary *configData; // data loaded from config plist
@property NSArray *checkResults; // the results of the checking
@property NSMutableArray *checkMessages; // an array of strings which are the messages that go into the next alert
@property NSString *lastStatusString; // the last overall status string we had
@property NSMutableDictionary *serviceStatusDict; // keep track of the last status of each service - so we can make a list of what changed
                                                  //@property NSMenu *menu;

@end

