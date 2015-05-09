//
//  FBLUserDetailsEmptyMessage.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/2/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const kUserDetailsBGView;

@interface FBLUserDetailsBGView : UIView

@property (unsafe_unretained, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *welcomeTitle;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *lowerTitle;
@property (weak, nonatomic) IBOutlet UIImageView *chattyImage;

@end
