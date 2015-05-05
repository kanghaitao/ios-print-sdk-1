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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HPPPView.h"
#import "HPPPPaper.h"

/*!
 * @abstract View that represents the graphical preview portion of the print preview
 */
@interface HPPPPageView : HPPPView


/*!
 * @abstract The preview image to display
 * @discussion Note that the preview displays a single image even when multiple print jobs are being printed.
 */
@property (strong, nonatomic) UIImage *image;

/*!
 * @abstract Indicates whether or not there are multiple images being printed
 */
@property (assign, nonatomic, getter=isMultipleImages) BOOL mutipleImages;

/*!
 * @abstract Indicates if the page curl animation is still in progress
 */
@property (assign, nonatomic) BOOL isAnimating;

/*!
 * @abstract Sets the preview to color mode
 * @param completion A block to be called when animation to color completes
 */
- (void)setColorWithCompletion:(void (^)(void))completion;

/*!
 * @abstract Sets the preview to black and white mode
 * @param completion A block to be called when animation to black and white completes
 */
- (void)setBlackAndWhiteWithCompletion:(void (^)(void))completion;

/*!
 * @abstract Changes the paper size with an optional animation
 * @param paperSize The new paper size
 * @param animated Boolean indicating whether or not to animate the transition to the new paper size
 * @param completion A block to be called when the paper transition is complete
 */
- (void)setPaperSize:(HPPPPaper *)paperSize animated:(BOOL)animated completion:(void (^)(void))completion;

@end
