//
//  FBLConnectionErrorEmptyMessageView.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/9/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

extern NSString* const kConnectionErrorBGView;
extern NSString* const kConnectionRetry;

@interface FBLConnectionErrorBGView : UIView
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIImageView *chatty;
@property (weak, nonatomic) IBOutlet UIButton *bubbleButton;
- (IBAction)animateBubbles:(id)sender;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (weak, nonatomic) IBOutlet UIButton *emailButton;
- (IBAction)sendEmail:(id)sender;

- (void)setDefaultState;
- (void)setRetryState;
- (void)setTryLaterState;

@end
