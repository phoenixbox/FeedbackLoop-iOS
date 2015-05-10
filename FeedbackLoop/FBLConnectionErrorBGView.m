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
        // Cache the original rects of the cloud locations
        NSLog(@"Left cloud width: %f", self.leftCloud.frame.size.width);
    }
    return self;
}

- (IBAction)cloudTrigger:(id)sender {
    // Animate the clouds
    [self floatLeftCloud];
    [self floatMiddleCloud];
    [self floatRightCloud];

    // Post reconnection message
    NSNotification *notification = [NSNotification notificationWithName:kConnectionRetry
                                                                 object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)floatLeftCloud {
    float displacement = 15.0f;

    CGRect frameStart = _leftCloud.frame;

    CGRect frame1 = CGRectMake(frameStart.origin.x - displacement,
                               frameStart.origin.y,
                               frameStart.size.width,
                               frameStart.size.height);

    CGRect frame2 = CGRectMake(frameStart.origin.x + displacement,
                               frame1.origin.y,
                               frameStart.size.width,
                               frameStart.size.height);


    [UIView animateKeyframesWithDuration:2.0
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat | UIViewAnimationOptionCurveLinear animations:^{
                                     [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
                                         _leftCloud.frame = frame1;
                                     }];
                                     [UIView addKeyframeWithRelativeStartTime:1.0 relativeDuration:1.0 animations:^{
                                         _leftCloud.frame = frame2;
                                     }];
                                 } completion:nil];
}

- (void)floatMiddleCloud {
    float displacement = 20.0f;

    CGRect frameStart = _middleCloud.frame;

    CGRect frame1 = CGRectMake(frameStart.origin.x - displacement,
                               frameStart.origin.y,
                               frameStart.size.width,
                               frameStart.size.height);

    CGRect frame2 = CGRectMake(frameStart.origin.x + displacement,
                               frame1.origin.y,
                               frameStart.size.width,
                               frameStart.size.height);


    [UIView animateKeyframesWithDuration:2.0
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat | UIViewAnimationOptionCurveLinear animations:^{
                                     [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
                                         _middleCloud.frame = frame1;
                                     }];
                                     [UIView addKeyframeWithRelativeStartTime:1.0 relativeDuration:1.0 animations:^{
                                         _middleCloud.frame = frame2;
                                     }];
                                 } completion:nil];

}

- (void)floatRightCloud {
    float displacement = 10.0f;

    CGRect frameStart = _rightCloud.frame;

    CGRect frame1 = CGRectMake(frameStart.origin.x + displacement,
                               frameStart.origin.y,
                               frameStart.size.width,
                               frameStart.size.height);

    CGRect frame2 = CGRectMake(frameStart.origin.x - displacement,
                               frame1.origin.y,
                               frameStart.size.width,
                               frameStart.size.height);


    [UIView animateKeyframesWithDuration:2.0
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat | UIViewAnimationOptionCurveLinear animations:^{
                                     [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
                                         _rightCloud.frame = frame1;
                                     }];
                                     [UIView addKeyframeWithRelativeStartTime:1.0 relativeDuration:1.0 animations:^{
                                         _rightCloud.frame = frame2;
                                     }];
                                 } completion:nil];

}

- (IBAction)sendEmail:(id)sender {
    NSLog(@"Compose Email Now");
}

- (void)setDefaultState {
    [_emailButton setHidden:YES];
    [self stopAnimatingClouds];
    self.contentView.layer.cornerRadius = 20;
    self.contentView.layer.borderWidth = 1;
    self.contentView.layer.borderColor = (__bridge CGColorRef)(WHITE);
    [self.contentView setBackgroundColor:FEEDBACK_BLUE_80];
    self.contentView.clipsToBounds = YES;

    [self.title setText:@"Whoops!"];
    [self.title setFont:[UIFont fontWithName:FEEDBACK_FONT size:34]];
    [self.chatty setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"ChattyNeutral.png"]]];
    [self.chatty setContentMode:UIViewContentModeScaleAspectFit];

    float bodySize = [FBLViewHelpers bodyCopyForScreenSize];
    [self.message setFont:[UIFont fontWithName:FEEDBACK_FONT size:bodySize]];

    [self.leftCloud setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"CloudA.png"]]];
    [self.leftCloud setContentMode:UIViewContentModeScaleAspectFit];

    [self.middleCloud setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"CloudB.png"]]];
    [self.middleCloud setContentMode:UIViewContentModeScaleAspectFit];

    [self.rightCloud setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"CloudA.png"]]];
    [self.rightCloud setContentMode:UIViewContentModeScaleAspectFit];
}

-(void)stopAnimatingClouds {
    NSArray *clouds = @[_leftCloud, _middleCloud, _rightCloud];

    for (UIImageView *image in clouds) {
        [image stopAnimating];
    }
}

- (void)setRetryState {
    [self stopAnimatingClouds];
    [self.title setText:@"Hmmmmm..."];
    [self.chatty setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"ChattyUnhappy.png"]]];
    [self.message setText:@"Tap the Clouds to try once more :)"];
}

- (void)setTryLaterState {
    [self stopAnimatingClouds];

    // Hide conflicting views
    [_cloudContainer setHidden:YES];
    [_cloudTrigger setHidden:YES];

    // Present the email dialog
    [_emailButton setHidden:NO];
    [_emailButton setTitle:@"Email Us" forState:UIControlStateNormal];
    [FBLViewHelpers setBaseButtonStyle:_emailButton withBGColor:WHITE titleColor:FEEDBACK_BLUE borderColor:FEEDBACK_BLUE];

    [self.title setText:@"Sorry!"];
    [self.chatty setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"Chatty.png"]]];
    [self.message setText:@"We can't connect right now"];
}

@end
