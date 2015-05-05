//
//  FBLContainerViewController.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/3/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FBLChatViewController.h"

@interface FBLContainerViewController : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UIView *headerView;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *closeButton;
- (IBAction)closeWindow:(id)sender;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *chatContainer;
@property (unsafe_unretained, nonatomic) IBOutlet UIImageView *logoImage;

@property (nonatomic, copy) void (^popWindow)();
@property (nonatomic, strong) FBLChatViewController *chatViewController;
@end
