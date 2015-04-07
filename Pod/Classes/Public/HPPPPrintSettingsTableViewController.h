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

#import <UIKit/UIKit.h>
#import "HPPPPrintSettings.h"

@protocol HPPPPrintSettingsTableViewControllerDelegate;

@interface HPPPPrintSettingsTableViewController : UITableViewController

@property (nonatomic, weak) id<HPPPPrintSettingsTableViewControllerDelegate> delegate;
@property (nonatomic, strong) HPPPPrintSettings *printSettings;
@property (nonatomic, assign) BOOL useDefaultPrinter;

@end


@protocol HPPPPrintSettingsTableViewControllerDelegate <NSObject>

- (void)printSettingsTableViewController:(HPPPPrintSettingsTableViewController *)paperTypeTableViewController didChangePrintSettings:(HPPPPrintSettings *)printSettings;

@end

