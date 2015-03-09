//
// Hewlett-Packard Company
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

#import "HPPP.h"
#import "HPPPAnalyticsManager.h"
#import <sys/sysctl.h>
#import <SystemConfiguration/CaptiveNetwork.h>

NSString * const kHPPPMetricsServer = @"print-metrics-w1.twosmiles.com/api/v1/mobile_app_metrics";
NSString * const kHPPPMetricsServerTestBuilds = @"print-metrics-test.twosmiles.com/api/v1/mobile_app_metrics";
//NSString * const kHPPPMetricsServerTestBuilds = @"localhost:4567/api/v1/mobile_app_metrics"; // use for local testing
NSString * const kHPPPMetricsUsername = @"hpmobileprint";
NSString * const kHPPPMetricsPassword = @"print1t";
NSString * const kHPPPOSType = @"iOS";
NSString * const kHPPPManufacturer = @"Apple";
NSString * const kHPPPNoNetwork = @"NO-WIFI";
NSString * const kHPPPNoPrint = @"No Print";
NSString * const kHPPPOfframpKey = @"off_ramp";
NSString * const kHPPPPrintActivity = @"HPPPPrintActivity";

@interface HPPPAnalyticsManager ()

@property (nonatomic, strong, readonly) NSString *userUniqueIdentifier;
@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

@end

@implementation HPPPAnalyticsManager

#pragma mark - Initialization

+ (HPPPAnalyticsManager *)sharedManager
{
    static HPPPAnalyticsManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        [sharedManager setupSettings];
    });
    
    return sharedManager;
}

- (void)setupSettings
{
    _userUniqueIdentifier = [[UIDevice currentDevice].identifierForVendor UUIDString];
    _dateFormatter = [[NSDateFormatter alloc] init] ;
    [_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
}

- (NSURL *)metricsServerURL
{
#ifdef APP_STORE_BUILD
    NSString *urlString = [NSString stringWithFormat:@"https://%@:%@@%@", kHPPPMetricsUsername, kHPPPMetricsPassword, kHPPPMetricsServer];
#else
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@", kHPPPMetricsUsername, kHPPPMetricsPassword, kHPPPMetricsServerTestBuilds];
#endif
    return [NSURL URLWithString:urlString];
}

#pragma mark - Gather metrics

- (NSDictionary *)baseMetrics
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *completeVersion = [NSString stringWithFormat:@"%@ (%@)", version, build];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *formattedTime = [self.dateFormatter stringFromDate:[NSDate date]];
    NSDictionary *metrics = @{
                              @"device_brand" : [self nonNullString:kHPPPManufacturer],
                              @"device_id" : [self nonNullString:self.userUniqueIdentifier],
                              @"device_type" : [self nonNullString:[self platform]],
                              @"manufacturer" : [self nonNullString:kHPPPManufacturer],
                              @"os_type" : [self nonNullString:kHPPPOSType],
                              @"os_version" : [self nonNullString:osVersion],
                              @"product_name" : [self nonNullString:displayName],
                              @"timestamp" : [self nonNullString:formattedTime],
                              @"version" : [self nonNullString:completeVersion],
                              @"wifi_ssid": [HPPPAnalyticsManager wifiName]
                              };

    return metrics;
}

- (NSDictionary *)printMetricsForOfframp:(NSString *)offramp
{
    if ([offramp isEqualToString:kHPPPPrintActivity]) {
        return [HPPP sharedInstance].lastOptionsUsed;
    } else {
        return [NSDictionary dictionaryWithObjectsAndKeys:
                kHPPPNoPrint, kHPPPBlackAndWhiteFilterId,
                kHPPPNoPrint, kHPPPNumberOfCopies,
                kHPPPNoPrint, kHPPPPaperSizeId,
                kHPPPNoPrint, kHPPPPaperTypeId,
                kHPPPNoPrint, kHPPPPrinterId,
                kHPPPNoPrint, kHPPPPrinterDisplayLocation,
                kHPPPNoPrint, kHPPPPrinterMakeAndModel,
                kHPPPNoPrint, kHPPPPrinterDisplayName,
                nil
                ];
    }
}

#pragma mark - Send metrics

- (void)trackShareEventWithOptions:(NSDictionary *)options
{
    NSMutableDictionary *metrics = [NSMutableDictionary dictionaryWithDictionary:[self baseMetrics]];
    [metrics addEntriesFromDictionary:[self printMetricsForOfframp:[options objectForKey:kHPPPOfframpKey]]];
    [metrics addEntriesFromDictionary:options];
    
    NSData *bodyData = [self postBodyWithValues:metrics];
    NSString *bodyLength = [NSString stringWithFormat: @"%ld", (long)[bodyData length]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[self metricsServerURL]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:bodyData];
    [urlRequest addValue:bodyLength forHTTPHeaderField: @"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self sendMetricsData:urlRequest];
    });
}

- (NSData *)postBodyWithValues:(NSDictionary *)values
{
    NSMutableArray *content = [NSMutableArray array];
    for (NSString * key in values) {
        [content addObject:[NSString stringWithFormat: @"%@=%@", key, values[key]]];
    }
    NSString *body = [content componentsJoinedByString: @"&"];
    return [body dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)sendMetricsData:(NSURLRequest *)request
{
    NSURLResponse *response = nil;
    NSError *connectionError = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
    
    if (connectionError == nil) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode != 200) {
                NSLog(@"HPPhotoPrint METRICS:  Response code = %ld", (long)statusCode);
                return;
            }
        }
        NSError *error;
        NSDictionary *returnDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        if (returnDictionary) {
            NSLog(@"HPPhotoPrint METRICS:  Result = %@", returnDictionary);
        } else {
            NSLog(@"HPPhotoPrint METRICS:  Parse Error = %@", error);
            NSString *returnString = [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSUTF8StringEncoding];
            NSLog(@"HPPhotoPrint METRICS:  Return string = %@", returnString);
        }
    } else {
        NSLog(@"HPPhotoPrint METRICS:  Connection error = %@", connectionError);
    }
}

# pragma mark - Helpers

- (NSString *)nonNullString:(NSString *)value
{
    return nil == value ? @"" : value;
}

// The following functions are adapted from http://stackoverflow.com/questions/448162/determine-device-iphone-ipod-touch-with-iphone-sdk

- (NSString *) platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

// The following code is adapted from http://stackoverflow.com/questions/4712535/how-do-i-use-captivenetwork-to-get-the-current-wifi-hotspot-name

+ (NSString *)wifiName {
    NSString *wifiName = kHPPPNoNetwork;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            wifiName = info[@"SSID"];
        }
    }
    return wifiName;
}

@end
