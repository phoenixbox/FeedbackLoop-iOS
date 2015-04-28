//
//  FeedbackLoop.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 4/26/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FeedbackLoop.h"

// Data Layer
#import "FBLAuthStore.h"

// Components
#import "FBLFeedbackTabBarController.h"

@interface FeedbackLoop ()
@property (nonatomic, strong) UIWindow *feedbackLoopWindow;
@end

@implementation FeedbackLoop

+ (FeedbackLoop *)sharedInstance {
    static dispatch_once_t once;
    static FeedbackLoop *feedbackLoop;

    dispatch_once(&once, ^ {
        feedbackLoop = [[self alloc] init];
    });

    return feedbackLoop;
}

+ (void)setApiKey:(NSString *)apiKey forAppId:(NSString *)appId;
    // Set the slack key in the auth store
}

+ (void)setSlackToken:(NSString *)slackToken {
    [[self sharedInstance] setSlackToken:slackToken];
}

+ (void)presentChatChannel {
    // Present the anyone chat channel
    FBLFeedbackTabBarController *feedbackTabBarViewController = [[FBLFeedbackTabBarController alloc] initWithNibName:kFeedbackTabBarController bundle:nil];
    feedbackTabBarViewController.modalPresentationStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:feedbackTabBarViewController animated:YES completion:nil];

    FeedbackLoop *singleton = [self sharedInstance];
    singleton.feedbackLoopWindow = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    [singleton.feedbackLoopWindow setWindowLevel:UIWindowLevelAlert];
    [singleton.feedbackLoopWindow makeKeyAndVisible];
}

+ (void)presentConversationList {
    // Present the historical conversation thread
}


@end