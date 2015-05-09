//
//  FBLBundleStore.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/2/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBLBundleStore : NSObject

+ (NSBundle *)frameworkBundle;

+ (NSString *)resourceNamed:(NSString *)namedResource;

@end
