//
//  FBLConnectionErrorEmptyMessageView.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/9/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLConnectionErrorBGView.h"

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

@end
