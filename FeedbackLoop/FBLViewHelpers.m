//
//  FBLViewHelpers.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/7/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLViewHelpers.h"
#import "FBLAppConstants.h"

@implementation FBLViewHelpers

+ (void)setBaseButtonStyle:(UIButton *)button withBGColor:(UIColor *)bg titleColor:(UIColor *)titleColor borderColor:(UIColor *)border {
    button.layer.cornerRadius = 4;
    button.layer.borderWidth = 2;
    button.layer.borderColor = (__bridge CGColorRef)(border);
    [button setBackgroundColor:bg];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button setTintColor:titleColor];
}

+ (float)bodyCopyForScreenSize {
    // TODO: Utilize for common appwide font size when necessary
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        // iPhone 4 - 3.5
        return 14.0f;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        // iPhone 5 - 4in
        return 15.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 375) {
        // iPhone 6 - 4.7in
        return 17.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 414) {
        // iPhone 6+ - 5.5in
        return 19.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 768) {
        // iPad
        NSLog(@"!WARN!: iPad not designed for");
        return 20.0f;
    }

    return 0;
}

+ (float)titleCopyForScreenSize {
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        // iPhone 4 - 3.5
        return 48.0f;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        // iPhone 5 - 4in
        return 52.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 375) {
        // iPhone 6 - 4.7in
        return 60.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 414) {
        // iPhone 6+ - 5.5in
        return 70.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 768) {
        // iPad - WARN
        return 70.0f;
    }

    return 0;
}

+ (float)buttonCopyForScreenSize {
    // TODO: Button Sizes should be ratios and not fixed dimensions so that the font size can scale
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        // iPhone 4 - 3.5
        return 15.0f;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        // iPhone 5 - 4in
        return 16.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 375) {
        // iPhone 6 - 4.7in
        return 16.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 414) {
        // iPhone 6+ - 5.5in
        return 16.0f;
    } else if ([UIScreen mainScreen].bounds.size.width == 768) {
        // iPad
        NSLog(@"!WARN!: iPad not designed for");
        return 16.0f;
    }

    return 0;
}

@end
