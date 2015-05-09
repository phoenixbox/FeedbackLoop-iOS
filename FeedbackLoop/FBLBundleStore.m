//
//  FBLBundleStore.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/2/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLBundleStore.h"
#import "FBLAppConstants.h"

@implementation FBLBundleStore

+ (NSBundle *)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:BUNDLE_NAME];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });

    return frameworkBundle;
}

+ (NSString *)resourceNamed:(NSString *)namedResource {
    return [[BUNDLE_NAME stringByAppendingString:@"/"] stringByAppendingString:namedResource];
}

@end