//
//  NagiosServer.m
//  MacNagios
//
//  Created by Kiko Albiol on 21/11/15.
//  Copyright © 2015 BGP. All rights reserved.
//

#import "NagiosServer.h"
#import "AppDelegate.h"

@interface NSURLRequest (DummyInterface)
+(BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+(void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

    static NSOperationQueue *queue()
    {
        static NSOperationQueue *que=nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            que=[[NSOperationQueue alloc] init];
        });
        return que;
    }


/**
 *  @brief  NagiosServer
 */
@implementation NagiosServer

-(BOOL)checkChangesAndRestoreStatus
{
    BOOL retval=self.hasChanged;
    if(retval)
        self.hasChanged=false;
    return retval;
}

-(NSString *)statusString
{
    NSString *thisStr = [NSString stringWithFormat:@"%@:%ld Total %ld OK, %ld Warn, %ld Crit",
                         self.name,
                         (long)self.totalCount,
                         self.okCount,
                         self.warnCount,
                         self.critCount
                         ];
    return thisStr;
}


+(instancetype)serverFromDictionary:(NSDictionary *)server
{
    NagiosServer *retval=[[NagiosServer alloc] initFromDictionary:server];
    //    NSDictionary *server = [serversArray objectAtIndex:i];
    
    return retval;
}

-(void)dealloc
{
    [self.timer invalidate];
    self.timer=nil;
}

-(instancetype)initFromDictionary:(NSDictionary *)server
{
    self=[super init];
    NSString *urlStr = [server objectForKey:@"url"];
    
    self.username = [server objectForKey:@"username"];
    self.password = [server objectForKey:@"password"];
    self.name=[server objectForKey:@"itemName"];
    self.adminURL=[[NSURL alloc] initWithString:[server objectForKey:@"adminURL"]];
    self.URL=[[NSURL alloc] initWithString:urlStr];
    self.ignoreSSLErrors=[[server objectForKey:@"ignoreSSLErrors"] boolValue];
    self.configData=[MacNagiosAppDelegate configFile];
    NSNumber *checkFrequencySeconds = [self.configData valueForKey:@"checkFrequencySeconds"];
    NSLog(@"checkFrequencySeconds: %@", checkFrequencySeconds);
    
    NSInteger checkFrequencySecondsInt = [checkFrequencySeconds integerValue];
    
    
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(timeoutHandler:)
                                   userInfo:nil
                                    repeats:NO];
    
    
    // subsequent times occur according to frequency
    [self setTimer:[NSTimer scheduledTimerWithTimeInterval:checkFrequencySecondsInt
                                                    target:self
                                                  selector:@selector(timeoutHandler:)
                                                  userInfo:nil
                                                   repeats:YES]];
    return self;
}


+(NSColor *)stateNumberToColor:(NSInteger)stateNum
{
    switch (stateNum) {
        case 0: return [NSColor greenColor];
        case 1: return [NSColor yellowColor];
        case 2: return [NSColor redColor];
        case 3: return [NSColor orangeColor];
        default: return nil;
    }
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

-(IBAction)openURL:(id)sender
{
    NSWorkspace *ws=[NSWorkspace sharedWorkspace];
    [ws openURL:self.URL];
    
}


- (void)timeoutHandler:(id)arg
{
    if(self.connection!=nil)
        return;
    if(nil==self.serviceStatusDict)
    {
        self.serviceStatusDict=[NSMutableDictionary dictionary];
    }
    if(nil==self.checkMessages)
    {
        self.checkMessages=[[NSArrayController alloc] init];
    }
    if(nil==self.allServices)
    {
        self.allServices=[[NSArrayController alloc] init];
    }
    
    
    
    NSString *username = self.username;
    NSString *password = self.password;
        
    // Prepare the link that is going to be used on the GET request
    NSURL * url = self.URL;
    
    
    //[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    
    
    // Prepare the request object
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval:30];
    
    if (username != nil && [username length] > 0)
    {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *authValue;
        if ([authData respondsToSelector:@selector(base64EncodedDataWithOptions:)]) { // base64EncodedDataWithOptions is 10.9+, tks to Volen Davidov for the tip
            authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];
        } else {
            authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];
        }
        
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    
    // Prepare the variables for the JSON response
    
    
    // Make synchronous request
    /*
     urlData = [NSURLConnection sendSynchronousRequest:urlRequest
     returningResponse:&response
     error:&error];
     */
    
    self.connection=[[NSURLConnection alloc] initWithRequest:urlRequest
                                                    delegate:self
                                            startImmediately:YES];
    
}


#pragma mark NSURLConnection Delegate Methods

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    NSError *anerror;
    // Construct a Array around the Data from the response
    NSDictionary* object = [NSJSONSerialization
                            JSONObjectWithData:self.responseData
                            options:0
                            error:&anerror];
    
    if(nil!=anerror)
    {
        NSLog(@"Error while getting URL %@: %@", connection.originalRequest , anerror);
        //NSLog(@"urlData: %@", [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding]);
        
        // add empty dictionary
        NSMutableDictionary *errorDict = [[NSMutableDictionary alloc] init];
        [errorDict setObject:@"error getting URL" forKey:@"_error"];
        [errorDict setObject:self.name forKey:@"_name"];
        [errorDict setObject:[self.adminURL absoluteString] forKey:@"_server"];
        //[results addObject:errorDict];
        NSLog(@"%@",errorDict);
        
        return;
    }
    self.connection=nil;
    self.responseData=nil;
    [self loadJsonFromServer:object];
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}






-(void)loadJsonFromServer:(NSDictionary *)data
{
    int okCount = 0;
    int warnCount = 0;
    int critCount = 0;
    int unkCount = 0;
    int totalCount = 0;
    
    
    NSDictionary* host_with_services = [data objectForKey:@"services"];
    
    if (host_with_services == nil)
    {
        // add empty dictionary
        NSMutableDictionary *errorDict = [[NSMutableDictionary alloc] init];
        [errorDict setObject:@"no 'services' entry, can't parse" forKey:@"_error"];
        [errorDict setObject:self.name forKey:@"_name"];
        [errorDict setObject:[self.adminURL absoluteString] forKey:@"_server"];
        //[results addObject:errorDict];
        NSLog(@"%@",errorDict);
        return;
    }
    
    // each individual host
    
    
    for (NSString *hostKey in host_with_services)
    {
        
        NSDictionary *hostDict = [host_with_services objectForKey:hostKey];
        
        for ( NSString *serviceKey in hostDict) {
            
            NSDictionary *serviceDict = [hostDict objectForKey:serviceKey];
            
            // if SkipIfNotificationsDisabled, silently skip any services that don't have notifications enabled
            NSNumber *notificationsDisabled = [self.configData objectForKey:@"SkipIfNotificationsDisabled"];
            if ([notificationsDisabled intValue]) {
                NSString *notificationsEnabled = [serviceDict valueForKey:@"notifications_enabled"];
                if ([notificationsEnabled isEqualToString:@"0"])
                {
                    continue;
                }
            }
            
            NSString *stateNum = [serviceDict valueForKey:@"last_hard_state"];
            if (stateNum == nil)
            {
                stateNum = [serviceDict valueForKey:@"current_state"];
            }
            switch ([stateNum intValue]) {
                case 0:
                    okCount++;
                    break;
                case 1:
                    warnCount++;
                    break;
                case 2:
                    critCount++;
                    break;
                case 3:
                default:
                    unkCount++;
                    break;
            }
            
            totalCount++;
            
            NSString *serviceStatusKey = [NSString stringWithFormat:@"%@/%@", hostKey, serviceKey];
            NSString *message=nil;
            NagiosService *nagiosService=self.serviceStatusDict[serviceStatusKey];
            if(nagiosService==nil)
            {
                nagiosService=[NagiosService serviceWithStatusInfo:serviceDict];
                nagiosService.parent=self;
                self.serviceStatusDict[serviceStatusKey]=nagiosService;
                [self.allServices addObject:nagiosService];
                self.hasChanged=YES;
                
            }
            else
            {
                message=[nagiosService updateValuesWithNewStatusInfo:serviceDict];
            }
            if ([message length] > 2)
            {
                [self.checkMessages addObject:@{@"date":[NSDate date],
                                                @"info":message,
                                                @"service":nagiosService}];
                self.hasChanged=YES;
            }
            
        }
        
    }
    
    self.okCount = okCount;
    self.warnCount = warnCount;
    self.critCount = critCount;
    self.unkCount = unkCount;
    self.totalCount = totalCount;
    if(self.hasChanged)
    {
        [self.parent refreshMenu];
    }
}

@end







@implementation NagiosService
/*
 
 "Forecasting Previsiones REE": {
 "host_name": "ree_oficial_information",
 "service_description": "Forecasting Previsiones REE",
 "modified_attributes": "0",
 "check_command": "check_electricas_service!previsiones_ree",
 "check_period": "24x7",
 "notification_period": "24x7",
 "check_interval": "5.000000",
 "retry_interval": "1.000000",
 "event_handler": "",
 "has_been_checked": "1",
 "should_be_scheduled": "1",
 "check_execution_time": "0.013",
 "check_latency": "0.193",
 "check_type": "0",
 "current_state": "0",
 "last_hard_state": "0",
 "last_event_id": "0",
 "current_event_id": "0",
 "current_problem_id": "0",
 "last_problem_id": "0",
 "current_attempt": "1",
 "max_attempts": "4",
 "state_type": "1",
 "last_state_change": "1446896077",
 "last_hard_state_change": "1446896077",
 "last_time_ok": "1448117078",
 "last_time_warning": "0",
 "last_time_unknown": "0",
 "last_time_critical": "0",
 "plugin_output": "previsiones_ree OK:No problems for this probe",
 "long_plugin_output": "",
 "performance_data": "0;1785",
 "last_check": "1448117078",
 "next_check": "1448117378",
 "check_options": "0",
 "current_notification_number": "0",
 "current_notification_id": "0",
 "last_notification": "0",
 "next_notification": "0",
 "no_more_notifications": "0",
 "notifications_enabled": "1",
 "active_checks_enabled": "1",
 "passive_checks_enabled": "1",
 "event_handler_enabled": "1",
 "problem_has_been_acknowledged": "0",
 "acknowledgement_type": "0",
 "flap_detection_enabled": "1",
 "failure_prediction_enabled": "1",
 "process_performance_data": "1",
 "obsess_over_service": "1",
 "last_update": "1448117347",
 "is_flapping": "0",
 "percent_state_change": "0.00",
 "scheduled_downtime_depth": "0"
 }

 */

+(instancetype)serviceWithStatusInfo:(NSDictionary *)serviceDict
{
    NagiosService *retval=[[NagiosService alloc] init];
    [retval updateValuesWithNewStatusInfo:serviceDict];
    retval.host=serviceDict[@"host_name"];
    
    return retval;
}

-(NSString *)updateValuesWithNewStatusInfo:(NSDictionary *)serviceDict
{
    NSString *retval=nil;
    self.itemDescription=serviceDict;
    
    NSInteger stateNum = [[serviceDict valueForKey:@"current_state"] intValue];
    if(stateNum!=self.lastStatus)
    {
        NSString *service=serviceDict[@"service_description"];
        NSString *host=serviceDict[@"ree_oficial_information" ];
        NSString *oldstatus=[NagiosServer stateNumberToString:self.lastStatus];
        NSString *newstatus=[NagiosServer stateNumberToString:stateNum];
        retval=[NSString stringWithFormat:@"%@ for Host %@ Status changed from:%@  to %@",service,host,oldstatus,newstatus];
        self.lastStatus=stateNum;
    }
    
    return retval;
}

-(NSString *)service
{
    return self.itemDescription[@"service_description"];
}

-(NSString *)pluginOutput
{
    return self.itemDescription[@"plugin_output"];
}

-(BOOL)hasServiceURLInformation
{
    NSArray *split=[(NSString *)self.itemDescription[@"plugin_output"] componentsSeparatedByString:@"@"];
    return [split count]==3 ? YES : NO;
}

-(NSURL *)URLInformation
{
    NSArray *split=[(NSString *)self.itemDescription[@"plugin_output"] componentsSeparatedByString:@"@"];
    if([split count]==3)
    {
        return [NSURL URLWithString:split[1]];
    }
    return nil;
}

-(NSURL *)URLTrends
{
    
    /*
      "https://lhcpheno07.ific.uv.es/nagios/cgi-bin/trends.cgi?";
    t1=1448107287&
    t2=1448193687&
    host=ree_oficial_information&
    service=Forecasting+Perdidas+Tarifas_015&
    assumeinitialstates=yes&
    assumestateretention=yes&
    assumestatesduringnotrunning=yes&
    includesoftstates=no&
    initialassumedhoststate=0&
    initialassumedservicestate=0&
    backtrack=4&
    timeperiod=lastweek&
    zoom=4";
     */
    
    NSInteger delta=1448107287-1448193687;
    
    NSInteger today=[[NSDate date] timeIntervalSince1970];
    NSInteger lastweek=[[NSDate dateWithTimeIntervalSinceNow:delta] timeIntervalSince1970];
    
    
    NSURL *retval=[self.parent.adminURL URLByAppendingPathComponent:@"cgi-bin"];
    retval=[retval URLByAppendingPathComponent:@"trends.cgi"];
    NSURLComponents *components=[NSURLComponents componentsWithString:[retval absoluteString]];
    NSArray *q=@[[NSURLQueryItem queryItemWithName:@"t1" value:[@(lastweek) stringValue]],
                 [NSURLQueryItem queryItemWithName:@"t2" value:[@(today) stringValue]],
                 [NSURLQueryItem queryItemWithName:@"assumeinitialstates" value:@"yes"],
                 [NSURLQueryItem queryItemWithName:@"assumestateretention" value:@"yes"],
                 [NSURLQueryItem queryItemWithName:@"assumestatesduringnotrunning" value:@"yes"],
                 [NSURLQueryItem queryItemWithName:@"includesoftstates" value:@"no"],
                 [NSURLQueryItem queryItemWithName:@"initialassumedhoststate" value:@"0"],
                 [NSURLQueryItem queryItemWithName:@"initialassumedservicestate" value:@"0"],
                 [NSURLQueryItem queryItemWithName:@"backtrack" value:@"4"],
                 [NSURLQueryItem queryItemWithName:@"timeperiod" value:@"lastweek"],
                 [NSURLQueryItem queryItemWithName:@"zoom" value:@"4"],
                 

                 [NSURLQueryItem queryItemWithName:@"host" value:self.itemDescription[@"host_name"]],
                 [NSURLQueryItem queryItemWithName:@"service" value:self.itemDescription[@"service_description"]]];
    components.queryItems=q;
    retval=[components URL];
    return retval;
}

-(NSURL *)URLAvailability
{
    /*
    https://lhcpheno07.ific.uv.es/nagios/cgi-bin/avail.cgi?
    host=ree_oficial_information&
    service=Forecasting+Perdidas+Tarifas_015&
    t1=1447542000&
    t2=1448146800&
    assumeinitialstates=yes&
    assumestateretention=no&
    assumestatesduringnotrunning=yes&
    includesoftstates=yes&
    initialassumedservicestate=0&
    backtrack=4&
    show_log_entries
     */
    
    NSInteger delta=1448107287-1448193687;
    
    NSInteger today=[[NSDate date] timeIntervalSince1970];
    NSInteger lastweek=[[NSDate dateWithTimeIntervalSinceNow:delta] timeIntervalSince1970];
    
    
    NSURL *retval=[self.parent.adminURL URLByAppendingPathComponent:@"cgi-bin"];
    retval=[retval URLByAppendingPathComponent:@"avail.cgi"];
    NSURLComponents *components=[NSURLComponents componentsWithString:[retval absoluteString]];
    NSArray *q=@[[NSURLQueryItem queryItemWithName:@"t1" value:[@(lastweek) stringValue]],
                 [NSURLQueryItem queryItemWithName:@"t2" value:[@(today) stringValue]],
                 [NSURLQueryItem queryItemWithName:@"assumeinitialstates" value:@"yes"],
                 [NSURLQueryItem queryItemWithName:@"assumestateretention" value:@"no"],
                 [NSURLQueryItem queryItemWithName:@"assumestatesduringnotrunning" value:@"yes"],
                 [NSURLQueryItem queryItemWithName:@"includesoftstates" value:@"yes"],
                 [NSURLQueryItem queryItemWithName:@"initialassumedservicestate" value:@"0"],
                 [NSURLQueryItem queryItemWithName:@"backtrack" value:@"4"],
                 [NSURLQueryItem queryItemWithName:@"show_log_entries" value:@""],
                 
                 [NSURLQueryItem queryItemWithName:@"host" value:self.itemDescription[@"host_name"]],
                 [NSURLQueryItem queryItemWithName:@"service" value:self.itemDescription[@"service_description"]]];
    components.queryItems=q;
    retval=[components URL];
    return retval;
}


-(NSURL *)URLService
{
    //Show Service Information //https://lhcpheno07.ific.uv.es/nagios/cgi-bin//extinfo.cgi?type=2&host=proceso_diario&service=Forecasting+Perdidas+Tarifa%3A+015
    NSURL *retval=[self.parent.adminURL URLByAppendingPathComponent:@"cgi-bin"];
    retval=[retval URLByAppendingPathComponent:@"extinfo.cgi"];
    NSURLComponents *components=[NSURLComponents componentsWithString:[retval absoluteString]];
    NSArray *q=@[[NSURLQueryItem queryItemWithName:@"type" value:@"2"],
                 [NSURLQueryItem queryItemWithName:@"host" value:self.itemDescription[@"host_name"]],
                 [NSURLQueryItem queryItemWithName:@"service" value:self.itemDescription[@"service_description"]]];
    components.queryItems=q;
    retval=[components URL];
    return retval;
}


-(IBAction)openURL:(id)sender
{
    NSURL *url=sender;
    [[NSWorkspace sharedWorkspace] openURL:url];
}

+(NSSet *)keyPathsForValuesAffectingColor
{
    return [NSSet setWithObject:@"lastStatus"];
}

+(NSSet *)keyPathsForValuesAffectingStatusDescription
{
    return [NSSet setWithObject:@"lastStatus"];
}

+(NSSet *)keyPathsForValuesAffectingHasServiceURLInformation
{
    return [NSSet setWithObject:@"lastStatus"];
}


-(id)valueForUndefinedKey:(NSString *)key
{
    if([self.itemDescription objectForKey:key])
    {
        return [self.itemDescription objectForKey:key];
    }
    @throw NSUndefinedKeyException;
    return nil;
}

-(NSColor *)color
{
    return [NagiosServer stateNumberToColor:self.lastStatus];
}


-(NSString *)statusDescription
{
    return [NagiosServer stateNumberToString:self.lastStatus];
}

@end







@implementation NagiosServiceTableCellView
-(NagiosService *)objectValue
{
    return (NagiosService *)[super objectValue];
}


-(void)setObjectValue:(NagiosService *)aserver
{
    return [super setObjectValue:aserver];
}

@end


@implementation NagiosServerTableCellView
-(NagiosServer *)objectValue
{
    return (NagiosServer *)[super objectValue];
}


-(void)setObjectValue:(NagiosServer *)aserver
{
    return [super setObjectValue:aserver];
}
@end





