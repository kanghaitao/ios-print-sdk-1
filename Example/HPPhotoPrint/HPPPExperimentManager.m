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

#import "HPPPExperimentManager.h"

@interface HPPPExperimentManager()

@property (strong, nonatomic) NSString *deviceID;

@end

@implementation HPPPExperimentManager

#pragma mark - Initialization

+ (HPPPExperimentManager *)sharedInstance
{
    static HPPPExperimentManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HPPPExperimentManager alloc] init];
        [sharedInstance updateVariationsWithDeviceID:[[UIDevice currentDevice].identifierForVendor UUIDString]];
    });
    
    return sharedInstance;
}

#pragma mark - Selection

- (void)updateVariationsWithDeviceID:(NSString *)deviceID
{
    if ([deviceID length] > 0) {
        NSArray *oddDigits = @[@"1", @"3", @"5", @"7", @"9", @"B", @"D", @"F"];
        NSString *lastDigit = [deviceID substringFromIndex:[deviceID length] - 1];
        _showPrintIcon = [oddDigits containsObject:lastDigit];
    } else {
        _showPrintIcon = NO;
    }
}

@end
