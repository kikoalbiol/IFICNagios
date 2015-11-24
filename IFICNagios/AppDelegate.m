//
//  AppDelegate.m
//  NagiosDock2
//
//  Created by Brad Peabody on 4/3/14.
//  Copyright (c) 2014 BGP. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreFoundation/CFBundle.h>
#import <ApplicationServices/ApplicationServices.h>
#import "NagiosServer.h"

@interface NSURLRequest (DummyInterface)
+(BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+(void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation MacNagiosAppDelegate
+(NSArray *)configPaths
{
    NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
    NSString *configPath = [bundlePath stringByAppendingPathComponent:@"ificnagios-config.plist"];
    
    
    NSArray *configPaths = @[[NSHomeDirectory() stringByAppendingPathComponent:@".ificnagios-config.plist"],
                             [NSHomeDirectory() stringByAppendingPathComponent:@"ificnagios-config.plist"],
                             configPath,
                             @"/etc/ificnagios-config.plist"
                             ];
    
    return configPaths;
}


+(NSMutableDictionary *)serverTemplate
{
    return [@{@"adminURL":@"https://ahost_remote.ific.uv.es/nagios/",
              @"itemName":@"New hostname",
              @"username":@"operator",
              @"password":@"xxxxxxxxxxxx",
              @"url":@"https://ahost_remote.ific.uv.es/nagios/statusJson.php",
              @"ignoreSSLErrors":@(NO)} mutableCopy];
}

+(NSMutableDictionary *)configurationTemplate
{
    return [@{@"checkFrequencySeconds":@(300),
             @"notifyOnChange":@(YES),
             @"notifyWithSound":@(YES),
             @"skipIfNotificationsDisabled":@(YES),
             @"servers":@[[MacNagiosAppDelegate serverTemplate]]
             } mutableCopy];
}


+(NSMutableDictionary *)configFile
{
    NSMutableDictionary *config = nil;

    for (NSString *path in [MacNagiosAppDelegate configPaths])
    {
        config = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        if (config != nil) { return [config mutableCopy]; }
    }
    config=[MacNagiosAppDelegate configurationTemplate];
    if(config[@"servers"])
    {
        NSMutableArray *newservers=[NSMutableArray array];
        for(NSDictionary *adict in config[@"servers"])
        {
            NSMutableDictionary *toinsert=[adict mutableCopy];
            if(nil==toinsert[@"ignoreSSLErrors"])
            {
                toinsert[@"ignoreSSLErrors"]=@(NO);
            }
            [newservers addObject:toinsert];
        }
        
    }
    return config;
}

-(NSInteger)minTimeInSecondsConfig
{
    return 30;
}

-(IBAction)saveConfigFile:(id)sender
{
    NSArray *files=[MacNagiosAppDelegate configPaths];
    [self.configData writeToFile:files[0] atomically:YES];
    [self reloadHosts];
}


-(BOOL)windowShouldClose:(id)sender
{
    [self.window orderOut:sender];
    return NO;
}


-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // we don't need this - should disable it altogether, but for now we just hide it
    // at app start
    // status string starts off empty
    [self setLastStatusString:@""];
    
    [self setServiceStatusDict:[[NSMutableDictionary alloc] init]];
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    [self setStatusItem:[bar statusItemWithLength:NSVariableStatusItemLength]];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    NSMutableDictionary *config = [MacNagiosAppDelegate configFile];

    if (config == nil)
    {
        
        NSLog(@"Cannot find macnagios-config.plist, nothing I can do about this - you fix it.");
        
        // we got issues, let the user know - so when the user first opens it, they have a hint of what to do
        
        NSAlert *alert = [[NSAlert alloc] init];
        //[alert setAlertStyle:NSRunInformationalAlertPanel];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"No nagios servers are configured!"];
        [alert setInformativeText:@"You'll need to create a macnagios-config.plist config file in order for this app to work correctly.  See the doc at https://github.com/bradleypeabody/MacNagios"];
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal] == NSAlertFirstButtonReturn)
        {
            //
        }
    }
    
    
    NSLog(@"loaded config dictionary: %@", config);
    {
        NSSortDescriptor *def_descrp=[NSSortDescriptor sortDescriptorWithKey:@"lastStatus" ascending:NO];
        
        NSDictionary *mainSortDict=@{@"name":@"By Status",
                                     @"sorter":@[def_descrp,[NSSortDescriptor sortDescriptorWithKey:@"host" ascending:NO]]};
        
        [self.sortOptions addObject:mainSortDict];
        [self.sortOptions addObject:@{@"name":@"By Service group",
                                      @"sorter":@[[NSSortDescriptor sortDescriptorWithKey:@"host" ascending:NO],def_descrp]}];
        [self.sortOptions setSelectedObjects:@[mainSortDict]];
    }
    {
        NSDictionary *mainSortDict=@{@"name":@"With Problems",
                                     @"predicate":[NSPredicate predicateWithFormat:@"lastStatus>0"]};
        
        [self.predicateOptions addObject:@{@"name":@"All services",
                                           @"predicate":[NSPredicate predicateWithValue:YES]}];

        [self.predicateOptions addObject:@{@"name":@"OK services",
                                           @"predicate":[NSPredicate predicateWithFormat:@"lastStatus==0"]}];
        [self.predicateOptions addObject:@{@"name":@"WARNING services",
                                           @"predicate":[NSPredicate predicateWithFormat:@"lastStatus==1"]}];

        [self.predicateOptions addObject:@{@"name":@"ERROR services",
                                           @"predicate":[NSPredicate predicateWithFormat:@"lastStatus==2"]}];

        [self.predicateOptions addObject:@{@"name":@"UNKNOWN services",
                                           @"predicate":[NSPredicate predicateWithFormat:@"lastStatus==3"]}];
        
        [self.predicateOptions addObject:mainSortDict];
        [self.predicateOptions setSelectedObjects:@[mainSortDict]];
    }

    
    self.configData=config;
    [self reloadHosts];
    
}

+(NSString *)stateNumberToString:(NSInteger)stateNum
{
    switch (stateNum) {
        case 0: return @"OK";
        case 1: return @"WARNING";
        case 2: return @"CRITICAL";
        case 3: return @"UNKNOWN";
        default: return nil;
    }
}

-(IBAction)quitHandler:(id)arg
{
    [NSApp terminate:self];
}



-(IBAction)reloadApplication:(id)sender
{
    [self reloadHosts];
}




-(void)refreshMenu
{
    NSInteger okCount = 0;
    NSInteger warnCount = 0;
    NSInteger critCount = 0;
    NSInteger unkCount = 0;
    NSInteger totalCount = 0;
    NSInteger hasChanged= 0;
    NSArray *menuItems=[[self.statusItem menu] itemArray];
    NSMutableArray *checkMessages=[NSMutableArray array];
    for(NSMenuItem *item in menuItems)
    {
        NagiosServer *nagiossrv=item.representedObject;
        if(nagiossrv)
        {
            if([nagiossrv isKindOfClass:[NagiosServer class]])
            {
                item.title=nagiossrv.statusString;
                okCount += nagiossrv.okCount;
                warnCount += nagiossrv.warnCount;
                critCount += nagiossrv.critCount;
                unkCount += nagiossrv.unkCount;
                totalCount += nagiossrv.totalCount;
            }
            if([nagiossrv checkChangesAndRestoreStatus])
            {
                NSArray *mess=[nagiossrv.checkMessages content];
                [checkMessages addObjectsFromArray:mess];
                [nagiossrv.checkMessages removeObjects:mess];
                hasChanged++;
            }
        }
    }
    
    NSString *str = [NSString stringWithFormat:@" %ld OK, %ld Warn, %ld Crit", okCount, warnCount, (long)critCount];
    [self.statusItem setTitle: str];
    
    if (totalCount < 1) {  // something wrong if there are no services at all
        [self.statusItem setImage: [NSImage imageNamed:@"nagios-icon-smaller-orange.png"]];
    } else if (critCount > 0) {
        [self.statusItem setImage: [NSImage imageNamed:@"nagios-icon-smaller-red.png"]];
    } else if (unkCount > 0) {
        [self.statusItem setImage: [NSImage imageNamed:@"nagios-icon-smaller-orange.png"]];
    } else if (warnCount > 0) {
        [self.statusItem setImage: [NSImage imageNamed:@"nagios-icon-smaller-yellow.png"]];
    } else { // okCount > 0
        [self.statusItem setImage: [NSImage imageNamed:@"nagios-icon-smaller-green.png"]];
    }
    
    [self.statusItem setHighlightMode:YES];
    
    BOOL notifyOnChange = [[self.configData objectForKey:@"notifyOnChange"] intValue];
    BOOL notifyWithSound = [[self.configData objectForKey:@"notifyWithSound"] intValue];
    
    if (notifyOnChange) {
        
        // send notification
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Nagios Status Changed";
        
        NSUInteger c = [checkMessages count];
        
        int showCount = 10;
        
        NSString *msg = [NSString stringWithFormat:@"%@ (%lu changed)", str, (unsigned long)c];
        for (NSString *line in checkMessages)
        {
            msg = [NSString stringWithFormat:@"%@\n%@", msg, line];
        }
        if (c > showCount) {
            msg = [NSString stringWithFormat:@"%@\n+%lu more...", msg, c-showCount];
        }
        notification.informativeText = msg;
        
        if (notifyWithSound) {
            notification.soundName = NSUserNotificationDefaultSoundName;
        }
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

-(IBAction)openWindowWithItem:(id)sender
{
    NSMenuItem *menuitem=sender;
    [self.serverList setSelectedObjects:@[menuitem.representedObject]];
    self.tabIndex=0;
    [[self window] makeKeyAndOrderFront:nil];
}


-(IBAction)openConfigWindow:(id)sender
{
    self.tabIndex=1;
    [[self window] makeKeyAndOrderFront:nil];
}


// called by timer to do the polling work
-(void)reloadHosts
{
    [self.serverList removeObjects:[self.serverList content]];

    // not sure if this 100% safe or if it's needed, but for our purposes should be fine
    
    NSLog(@"reloadHosts");
    
    NSArray *serversArray = [self.configData valueForKey:@"servers"];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"MacNagios"];

    
    for(NSDictionary *server in serversArray)
    {
        NSLog(@"%@",server);
        NagiosServer *nagiossrv=[NagiosServer serverFromDictionary:server];
        nagiossrv.parent=self;
        [[self serverList] addObject:nagiossrv];
        NSMenuItem *menuitem=[[NSMenuItem alloc] init];
        menuitem.title=nagiossrv.statusString;
        menuitem.representedObject=nagiossrv;
        menuitem.target=self;
        menuitem.action=@selector(openWindowWithItem:);
        [menu addItem:menuitem];
    }
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Open Configuration Window" action:@selector(openConfigWindow:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Reolad..." action:@selector(reloadApplication:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit" action:@selector(quitHandler:) keyEquivalent:@""];
    [self.statusItem setMenu:menu];
    [self refreshMenu];
}

-(IBAction)actionByTag:(id)sender
{
    NSInteger tag=[sender tag];
    NSWorkspace *ws=[NSWorkspace sharedWorkspace];
    NagiosService *service=[[self.serviceList selectedObjects] lastObject];
    NagiosServer *server=[[self.serverList selectedObjects] lastObject];
    switch (tag) {
        case 0:
            //Show Web Page
            [ws openURL:server.adminURL];
            break;
        case 1: //URLInformation            
            [ws openURL:service.URLService];
            break;
        case 2:
            [ws openURL:service.URLInformation];
            break;
        case 3:
            [ws openURL:service.URLTrends];
            break;
        case 4:
            [ws openURL:service.URLAvailability];
            break;
            
        default:
            break;
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end















/**
 *  @brief  Nuevo host
 */

@implementation ArrayControllerForConfigurationHost


-(id)newObject
{
    return [MacNagiosAppDelegate serverTemplate];
}
@end










