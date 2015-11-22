//
//  NagiosServer.h
//  MacNagios
//
//  Created by Kiko Albiol on 21/11/15.
//  Copyright © 2015 BGP. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MacNagiosAppDelegate;


@interface NagiosServer : NSObject
@property (assign) MacNagiosAppDelegate *parent;
@property (retain) NSString *name;
@property (retain) NSURL *URL;
@property (retain) NSURL *adminURL;
@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSTimer *timer;
@property (assign) CGFloat checkFrequencySecondsInt;
@property (retain) NSDictionary *configData;

@property (retain) NSMutableDictionary *serviceStatusDict;
@property (retain) NSArrayController *checkMessages;
@property (retain) NSArrayController *allServices;

@property (assign) NSInteger okCount;// = 0;
@property (assign) NSInteger warnCount;// = 0;
@property (assign) NSInteger critCount;// = 0;
@property (assign) NSInteger unkCount;// = 0;
@property (assign) NSInteger totalCount;// = 0;

@property (readonly) NSString *statusString;
@property (assign) BOOL hasChanged;

-(IBAction)openURL:(id)sender;

+(instancetype)initFromDictionary:(NSDictionary *)adict;
+(instancetype)serverFromDictionary:(NSDictionary *)adict;
+(NSString *)stateNumberToString:(NSInteger)stateNum;
+(NSColor *)stateNumberToColor:(NSInteger)stateNum;


-(BOOL)checkChangesAndRestoreStatus;
@end
/**
 *  @brief  The corresponding cellview
 */
@interface NagiosServerTableCellView : NSTableCellView
@property (retain) NagiosServer *objectValue;
@end



/**
 *  @brief  Service descriptor
 */
@interface NagiosService : NSObject
@property (assign) NagiosServer *parent;
@property (retain) NSString *host;
@property (readonly) NSString *service;
@property (readonly) NSString *pluginOutput;
@property (retain) NSDictionary *itemDescription;
@property (assign) NSInteger lastStatus;
@property (readonly) NSColor *color;
@property (readonly) NSString *statusDescription;
@property (readonly) BOOL hasServiceURLInformation;
@property (readonly) NSURL *URLInformation;
@property (readonly) NSURL *URLService;
@property (readonly) NSURL *URLTrends;
@property (readonly) NSURL *URLAvailability;



+(instancetype)serviceWithStatusInfo:(NSDictionary *)adict;
-(NSString *)updateValuesWithNewStatusInfo:(NSDictionary *)adict;

-(IBAction)openURL:(id)sender;
@end


/**
 *  @brief  The corresponding cellview
 */


@interface NagiosServiceTableCellView : NSTableCellView
@property (retain) NagiosService *objectValue;
@end



