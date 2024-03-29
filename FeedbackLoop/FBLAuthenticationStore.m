//
//  FBLAuthenticationStore.m
//  Stndout
//
//  Created by Shane Rogers on 4/27/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import "FBLAuthenticationStore.h"
#import "FBLTeamStore.h"
#import "FBLTeam.h"

// Constants
#import "FBLAppConstants.h"

@implementation FBLAuthenticationStore

+ (FBLAuthenticationStore *)sharedInstance {
    static FBLAuthenticationStore *authStore = nil;

    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        authStore = [[FBLAuthenticationStore alloc] init];
    });

    return authStore;
}

- (NSString *)authenticateRequest:(NSString *)requestURL {
    requestURL = [requestURL stringByAppendingString:(@"?token=")];
    requestURL = [requestURL stringByAppendingString:self.slackToken];

    return requestURL;
}

- (NSString *)oauthRequest:(NSString *)requestURL {
    requestURL = [requestURL stringByAppendingString:(@"?token=")];
    requestURL = [requestURL stringByAppendingString:self.slackToken];

    return requestURL;
}

- (NSString *)oauthRequest:(NSString *)requestURL withURLSegment:(NSString *)urlSegment {
    if (urlSegment) {
        requestURL = [requestURL stringByAppendingString:urlSegment];
    }

    return [self oauthRequest:requestURL];
}

- (NSString *)authenticateRequest:(NSString *)requestURL withURLSegment:(NSString *)urlSegment {
    if (urlSegment) {
        requestURL = [requestURL stringByAppendingString:urlSegment];
    }

    return [self authenticateRequest:requestURL];
}

- (NSString *)feedbackLoopAuthURL {
    // http://localhost:3000/api/teams/64a702c6-d868-480a-aff1-1ec6ab90e267?email=shane@gmail.com
    // FBL: 032c2adc-76f8-4ba6-b1ff-5602e8d432d9
    NSString *BASE_URL = PROD_API_BASE_URL;
    // Reassign for local development
//#ifdef DEBUG
//    BASE_URL = DEV_API_BASE_URL;
//#endif
    NSString *requestURL = [BASE_URL stringByAppendingString:FBL_TEAMS_URI];
    requestURL = [NSString stringWithFormat:@"%@/%@%@", requestURL, self.AppId,@"?"];
    requestURL = [NSString stringWithFormat:@"%@email=%@", requestURL, self.userEmail];
    
    return requestURL;
}


@end
