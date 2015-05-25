//
//  FBLConnectionErrorEmptyMessageView.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/9/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLConnectionErrorBGView.h"


// Data Layer
#import "FBLBundleStore.h"

// Constants
#import "FBLAppConstants.h"

// Helpers
#import "FBLViewHelpers.h"

NSString *const kConnectionErrorBGView = @"FBLConnectionErrorBGView";
NSString *const kConnectionRetry = @"feedbackLoop__connectionRetry";

@implementation FBLConnectionErrorBGView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        [_hud setCenter:self.center];
        _hud.mode = MBProgressHUDModeIndeterminate;
    }
    return self;
}

- (IBAction)sendEmail:(id)sender {
    NSLog(@"Compose Email Now");
}

- (void)setDefaultState {
    [_hud hide:YES];
    [_emailButton setHidden:YES];

    self.contentView.layer.cornerRadius = 20;
    self.contentView.layer.borderWidth = 1;
    self.contentView.layer.borderColor = (__bridge CGColorRef)(WHITE);
    [self.contentView setBackgroundColor:FEEDBACK_BLUE_80];
    self.contentView.clipsToBounds = YES;

    [self.title setText:@"Whoops!"];
    [self.title setFont:[UIFont fontWithName:FEEDBACK_FONT size:34]];
    [self.chatty setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"Bang.png"]]];
    [self.chatty setContentMode:UIViewContentModeScaleAspectFit];

    float bodySize = [FBLViewHelpers bodyCopyForScreenSize];
    [self.message setFont:[UIFont fontWithName:FEEDBACK_FONT size:bodySize]];
}

- (void)setRetryState {
//    [_hud hide:NO];
    [self.title setText:@"Try Again"];
    [self.chatty setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"BangBang.png"]]];
    [self.message setText:@"Tap to try once more :)"];
}

- (void)setTryLaterState {
    // Hide conflicting views
//    [_hud hide:YES];
    [_bubbleButton setHidden:YES];
    [_chatty setHidden:YES];

    // Present the email dialog
    [_emailButton setHidden:NO];
    [_emailButton setTitle:@"Email Us" forState:UIControlStateNormal];
    [FBLViewHelpers setBaseButtonStyle:_emailButton withBGColor:WHITE titleColor:FEEDBACK_BLUE borderColor:FEEDBACK_BLUE];

    [self.title setText:@"Sorry!"];
    [self.message setText:@"We can't connect right now"];
}

- (IBAction)animateBubbles:(id)sender {
    [_hud hide:NO];
    // Post reconnection message
    NSNotification *notification = [NSNotification notificationWithName:kConnectionRetry
                                                                 object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
