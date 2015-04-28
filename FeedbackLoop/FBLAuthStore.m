//
//  FBLAuthStore.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 4/26/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLAuthStore.h"

@implementation FBLAuthStore

+ (FBLAuthStore *)sharedInstance {
    static FBLAuthStore *authStore = nil;

    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        authStore = [[FBLAuthStore alloc] init];
    });

    return authStore;
}

+ (NSString *)authenticateRequest:(NSString *)requestURL {
    requestURL = [requestURL stringByAppendingString:(@"?token=")];
    NSString * slackToken = [[self sharedInstance] slackToken];
    requestURL = [requestURL stringByAppendingString:slackToken];

    return requestURL;
}

+ (NSString *)authenticateRequest:(NSString *)requestURL withURLSegment:(NSString *)urlSegment {
    if (urlSegment) {
        requestURL = [requestURL stringByAppendingString:urlSegment];
    }

    return [FBLAuthStore authenticateRequest:requestURL];
}

@end