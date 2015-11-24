//
//  IFICNSURLSession.m
//  IFICNagios
//
//  Created by Kiko Albiol on 24/11/15.
//  Copyright © 2015 BGP. All rights reserved.
//

#import "IFICNSURLSession.h"

@implementation IFICNSURLSession

-(id)init
{
    self=[super init];
#if TARGET_OS_IPHONE
    self.completionHandlerDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
#endif
    
    /* Create some configuration objects. */
    
    NSURLSessionConfiguration *backgroundConfigObject = [NSURLSessionConfiguration backgroundSessionConfiguration: @"myBackgroundSessionIdentifier"];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSessionConfiguration *ephemeralConfigObject = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    
    /* Configure caching behavior for the default session.
     Note that iOS requires the cache path to be a path relative
     to the ~/Library/Caches directory, but OS X expects an
     absolute path.
     */
#if TARGET_OS_IPHONE
    NSString *cachePath = @"/MyCacheDirectory";
    
    NSArray *myPathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *myPath    = [myPathList  objectAtIndex:0];
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString *fullCachePath = [[myPath stringByAppendingPathComponent:bundleIdentifier] stringByAppendingPathComponent:cachePath];
    NSLog(@"Cache path: %@\n", fullCachePath);
#else
    NSString *cachePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/nsurlsessiondemo.cache"];
    
    NSLog(@"Cache path: %@\n", cachePath);
#endif
    
    
    
    
    
    NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: cachePath];
    defaultConfigObject.URLCache = myCache;
    defaultConfigObject.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    
    /* Create a session for each configurations. */
    self.defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    self.backgroundSession = [NSURLSession sessionWithConfiguration: backgroundConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    self.ephemeralSession = [NSURLSession sessionWithConfiguration: ephemeralConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];

    return self;
}

@end
