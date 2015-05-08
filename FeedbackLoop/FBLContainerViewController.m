//
//  FBLContainerViewController.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/3/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLContainerViewController.h"
#import "FBLBundleStore.h"
#import "FBLAppConstants.h"

#import "FBLHelpers.h"

@interface FBLContainerViewController ()

@end

@implementation FBLContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _chatViewController = [[FBLChatViewController alloc] init];
    _chatViewController.popWindow = _popWindow;

    [self addChildViewController:_chatViewController];

    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    [_chatViewController.view setFrame:CGRectMake(0,0,screenSize.width, screenSize.height - _headerView.frame.size.height)];
    [_headerView setFrame:CGRectMake(0,0,screenSize.width, _headerView.frame.size.height)];
    [self attributeNavBar];
    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, _headerView.frame.size.height -2 , screenSize.width, 2)];
    [border setBackgroundColor:FEEDBACK_BLUE];
    [_headerView addSubview:border];

    [_chatContainer addSubview:_chatViewController.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)attributeNavBar {
    [_headerView setBackgroundColor:[UIColor whiteColor]];

    _logoImage.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *titleImage = [UIImage imageWithContentsOfFile:[[FBLBundleStore frameworkBundle] pathForResource:@"FBLTitle" ofType:@"png"]];
    [_logoImage setImage:titleImage];

    UIImage *closeImage = [UIImage imageWithContentsOfFile:[[FBLBundleStore frameworkBundle] pathForResource:    ResourceExtension(@"closeWindow") ofType:@"png"]];
    [_closeButton setBackgroundImage:closeImage forState:UIControlStateNormal];

    UIImage *closeImageSelected = [UIImage imageWithContentsOfFile:[[FBLBundleStore frameworkBundle] pathForResource:    ResourceExtension(@"closeWindowSelected") ofType:@"png"]];
    [_closeButton setBackgroundImage:closeImageSelected forState:UIControlStateHighlighted];
    [_closeButton setBackgroundImage:closeImageSelected forState:UIControlStateSelected];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)closeWindow:(id)sender {
    [_chatViewController hideFeedbackLoopWindow];
}

@end
