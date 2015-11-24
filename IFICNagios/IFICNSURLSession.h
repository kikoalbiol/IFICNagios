//
//  IFICNSURLSession.h
//  IFICNagios
//
//  Created by Kiko Albiol on 24/11/15.
//  Copyright © 2015 BGP. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionHandlerType)();

@interface IFICNSURLSession : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
@property NSURLSession *backgroundSession;
@property NSURLSession *defaultSession;
@property NSURLSession *ephemeralSession;

#if TARGET_OS_IPHONE
@property NSMutableDictionary *completionHandlerDictionary;
#endif

- (void) addCompletionHandler: (CompletionHandlerType) handler forSession: (NSString *)identifier;
- (void) callCompletionHandlerForSession: (NSString *)identifier;




@end
