//
//  FBLAuthStore.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 4/26/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBLAuthStore : NSObject

@property (nonatomic, strong) NSString *slackToken;
@property (nonatomic, strong) NSString *feedbackLoopToken;

+ (FBLAuthStore *)sharedInstance;

+ (NSString *)authenticateRequest:(NSString *)requestURL;
+ (NSString *)authenticateRequest:(NSString *)requestURL withURLSegment:(NSString *)urlSegment;

@end