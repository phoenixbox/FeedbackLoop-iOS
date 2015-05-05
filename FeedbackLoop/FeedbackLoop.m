//
//  FeedbackLoop.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 4/27/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import "FeedbackLoop.h"

// Data Layer
#import "FBLAuthenticationStore.h"
#import "FBLAppConstants.h"

#import "FBLBundleStore.h"

// Components
#import "FBLContainerViewController.h"

static NSString * const kFeedbackTabBarController = @"FBLFeedbackTabBarController";
static NSString * const kContainerViewController = @"FBLContainerViewController";

@interface FeedbackLoop ()
@property (nonatomic, strong) UIWindow *feedbackLoopWindow;
@property (nonatomic, strong) FBLContainerViewController *containerViewController;
@property (nonatomic, strong) NSBundle *frameworkBundle;
@end

@implementation FeedbackLoop

+ (FeedbackLoop *)sharedInstance {
    static dispatch_once_t once;
    static FeedbackLoop *feedbackLoop;

    dispatch_once(&once, ^ {
        feedbackLoop = [[self alloc] init];
        
        [FBLBundleStore frameworkBundle];
    });

    return feedbackLoop;
}

+ (void)initWithSlackToken:(NSString *)slackToken {
    FBLAuthenticationStore *store = [FBLAuthenticationStore sharedInstance];
    
    [store setSlackToken:slackToken];
}

+ (void)initWithAppId:(NSString *)appId {
    FBLAuthenticationStore *store = [FBLAuthenticationStore sharedInstance];

    [store setAppId:appId];
}

+ (void)setApiKey:(NSString *)apiKey forAppId:(NSString *)appId {
}

+ (void)registerUserWithEmail:(NSString *)userEmail {
    FBLAuthenticationStore *store = [FBLAuthenticationStore sharedInstance];
    [store setUserEmail:userEmail];
}

+ (void)presentChatChannel {
    FeedbackLoop *singleton = [self sharedInstance];
    if (singleton.feedbackLoopWindow && singleton.feedbackLoopWindow.hidden) {
        [singleton.feedbackLoopWindow setHidden:NO];
    }

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    singleton.feedbackLoopWindow = [[UIWindow alloc]initWithFrame:screenBounds];
    [singleton.feedbackLoopWindow setWindowLevel:UIWindowLevelAlert];

    void (^popWindow)() = ^void() {
        [self popWindow];
    };

    NSBundle *bundle = [FBLBundleStore frameworkBundle];
    singleton.containerViewController = [[FBLContainerViewController alloc] initWithNibName:kContainerViewController bundle:bundle];
    singleton.containerViewController.popWindow = popWindow;
    
    [singleton.feedbackLoopWindow setRootViewController:singleton.containerViewController];
    [singleton.feedbackLoopWindow makeKeyAndVisible];
}

+ (void)popWindow {
    FeedbackLoop *singleton = [self sharedInstance];
    NSLog(@"Remove FeedbackLoop Window");
    singleton.feedbackLoopWindow = nil;
}

@end