//
//  FBLSlackStore.m
//  Stndout
//
//  Created by Shane Rogers on 4/19/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import "FBLSlackStore.h"

// Data Layer
#import "FBLAuthenticationStore.h"
#import "FBLMembersStore.h"
#import "FBLChannelStore.h"
#import "FBLTeam.h"
#import "FBLTeamStore.h"

// Constants
#import "FBLAppConstants.h"

// Libs
#import "AFNetworking.h"

@implementation FBLSlackStore

+ (FBLSlackStore *)sharedStore {
    static FBLSlackStore *slackStore = nil;

    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        slackStore = [[FBLSlackStore alloc] init];
    });

    return slackStore;
}

- (void)setupWebhook:(void (^)(NSError *err))block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSString *requestURL = [[FBLAuthenticationStore sharedInstance] authenticateRequest:SLACK_API_BASE_URL withURLSegment:SLACK_API_RTM_START];

    [manager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary *rtmResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];

        // Why doesnt onject for key return "0" resolve as false
        NSNumber *ok = [rtmResponse objectForKey:@"ok"];
        if ([ok isEqual:@(YES)]) {
            self.webhookUrl = [rtmResponse objectForKey:@"url"];
            [[FBLMembersStore sharedStore] refreshMembersWithCollection:[rtmResponse objectForKey:@"users"]];
            [[FBLMembersStore sharedStore] processMemberPhotos];
            [[FBLChannelStore sharedStore] refreshChannelsWithCollection:[rtmResponse objectForKey:@"channels"]];
            block(nil);
        } else {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Couldnt setup webhook!", nil),
                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                                       };
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                 code:-1008
                                             userInfo:userInfo];
            block(error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(error);
    }];
}

- (void)joinOrCreateChannel:(void (^)(NSError *err))block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSString *requestURL = [[FBLAuthenticationStore sharedInstance] authenticateRequest:SLACK_API_BASE_URL withURLSegment:SLACK_API_CHANNEL_JOIN];

    requestURL = [requestURL stringByAppendingString:(@"&name=")];
    NSString *userEmail = [[FBLAuthenticationStore sharedInstance] userEmail];
    requestURL = [requestURL stringByAppendingString:userEmail];

    [manager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];

        NSNumber *ok = [response objectForKey:@"ok"];
        if ([ok isEqual:@(YES)]) {
            _userChannelId = [[response objectForKey:@"channel"] objectForKey:@"id"];
            block(nil);
        } else {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Couldnt join channel!", nil),
                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                                       };
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                 code:-1008
                                             userInfo:userInfo];
            block(error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(error);
    }];
}

- (void)feedbackLoopAuth:(void (^)(FBLChatCollection *chatHistory, NSError *err))block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSString *requestURL = [[FBLAuthenticationStore sharedInstance] channelForEmailRegUser];
    NSLog(@"FeedbackLoop Oauth request URL %@", requestURL);
    
    [manager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        FeedbackLoop API Response
        //        team ? {team ,rtm, channel} : {error}
        NSMutableDictionary *oauthRequest = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];

        NSString *err = [oauthRequest objectForKey:@"error"];

        if (!err) {
            // **** 0. Extract the response objects
            NSDictionary *teamAttrs = [oauthRequest objectForKey:@"team"];
            NSDictionary *channel = [oauthRequest objectForKey:@"channel"];
            NSDictionary *rtm = [oauthRequest objectForKey:@"rtm"];

            // **** 1. Process the team attrs
            // Set the team on the team store
            FBLTeam *fblTeam = [[FBLTeam alloc] initWithDictionary:teamAttrs error:nil];
            [fblTeam buildToken];
            // TODO: Clean up this interface: team doesnt need a slack token - the auth store does
            [[FBLAuthenticationStore sharedInstance] setSlackToken:fblTeam.slackToken];
            NSString *teamImage = [[[rtm objectForKey:@"team"] objectForKey:@"icon"] objectForKey:@"image_132"];
            [fblTeam setTeamImage:teamImage];
            [[FBLTeamStore sharedStore] setTeam:fblTeam];

            // **** 2. Process the channel attrs
            _userChannelId = [channel objectForKey:@"channel_id"];
            // scheme {channel: {channel_id, messsages}}
            // Chat history via JSON model has an array of messages which maps to the nested messages key
            FBLChatCollection *chatHistory = [[FBLChatCollection alloc] initWithDictionary:channel error:nil];
            [chatHistory loadMediaForMessages];

            // **** 3. Process the rtm
            self.webhookUrl = [rtm objectForKey:@"url"];

            [[FBLMembersStore sharedStore] refreshMembersWithCollection:[rtm objectForKey:@"users"]];
            [[FBLMembersStore sharedStore] processMemberPhotos];
            [[FBLChannelStore sharedStore] refreshChannelsWithCollection:[rtm objectForKey:@"channels"]];


            block(chatHistory, nil);
        } else {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"RTM request error!", nil),
                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                                       };
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                 code:-1008
                                             userInfo:userInfo];
            block(nil, error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(nil, error);
    }];
}

@end