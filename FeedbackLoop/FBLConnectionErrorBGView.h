//
//  FBLConnectionErrorEmptyMessageView.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/9/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const kConnectionErrorBGView;

@interface FBLConnectionErrorBGView : UIView
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIImageView *chatty;
@property (weak, nonatomic) IBOutlet UIView *cloudContainer;

@property (weak, nonatomic) IBOutlet UIImageView *rightCloud;
@property (weak, nonatomic) IBOutlet UIImageView *middleCloud;
@property (weak, nonatomic) IBOutlet UIImageView *leftCloud;
@property (weak, nonatomic) IBOutlet UIButton *cloudTrigger;
- (IBAction)cloudTrigger:(id)sender;

@end
