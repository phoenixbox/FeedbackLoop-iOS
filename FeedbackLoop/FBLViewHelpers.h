//
//  FBLViewHelpers.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/7/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FBLViewHelpers : NSObject

+ (void)setBaseButtonStyle:(UIButton *)button withBGColor:(UIColor *)bg titleColor:(UIColor *)titleColor borderColor:(UIColor *)border;

+ (float)bodyCopyForScreenSize;

+ (float)titleCopyForScreenSize;

+ (float)buttonCopyForScreenSize;

@end
