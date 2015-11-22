//
//  AppDelegate.h
//  MacNagios
//
//  Created by Brad Peabody on 4/4/14.
//  Copyright (c) 2014 BGP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class ArrayControllerForConfigurationHost;

@interface MacNagiosAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate,NSWindowDelegate>
{

}
@property (retain) IBOutlet NSArrayController *checkMessages;
@property (retain) IBOutlet NSArrayController *serverList;
@property (retain) IBOutlet NSArrayController *serviceList;

@property (retain) IBOutlet NSArrayController *sortOptions;
@property (retain) IBOutlet NSArrayController *predicateOptions;


@property (assign) IBOutlet NSWindow *window;

@property (assign) NSInteger tabIndex;
@property (readonly) NSInteger minTimeInSecondsConfig;
@property (retain) NSStatusItem *statusItem;
@property (retain) NSString *lastStatusString;
@property (retain) NSMutableDictionary *serviceStatusDict;
@property (retain) NSMutableDictionary *configData;
@property (retain) NSArrayController *checkResults; // the results of the checking

+(NSArray *)configPaths;
+(NSMutableDictionary *)configFile;
+(NSString *)stateNumberToString:(NSInteger)stateNum;
+(NSMutableDictionary *)serverTemplate;
+(NSMutableDictionary *)configurationTemplate;


-(IBAction)quitHandler:(id)arg;
-(IBAction)openWindowWithItem:(id)sender;
-(IBAction)saveConfigFile:(id)sender;
-(IBAction)reloadApplication:(id)sender;


-(IBAction)actionByTag:(id)sender;
-(void)reloadHosts;


-(void)refreshMenu;

@end


@interface ArrayControllerForConfigurationHost : NSArrayController


@end






