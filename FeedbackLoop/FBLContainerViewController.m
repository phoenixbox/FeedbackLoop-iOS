//
//  FBLContainerViewController.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/3/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLContainerViewController.h"
#import "FBLChatViewController.h"
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

    // Header View
    [_headerView setFrame:CGRectMake(0,0,screenSize.width, _headerView.frame.size.height)];
    // Error Message View
    [_errorMessage setFrame:CGRectMake(0, 20, screenSize.width, 30)];
    [_errorMessage setBackgroundColor:[UIColor redColor]];

    [self attributeNavBar];

    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, _headerView.frame.size.height -2 , screenSize.width, 2)];
    [border setBackgroundColor:FEEDBACK_BLUE];
    [_headerView addSubview:border];


    [_chatContainer addSubview:_chatViewController.view];
    [self listenForErrorNotification];
}


- (void)listenForErrorNotification {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(toggleGlobalNotifcation:)
                   name:kGlobalNotification
                 object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)attributeNavBar {
    [_headerView setBackgroundColor:[UIColor whiteColor]];

    _logoImage.contentMode = UIViewContentModeScaleAspectFit;

    // Set title image
    UIImage *titleImage = [UIImage imageNamed:[FBLBundleStore resourceNamed:@"FBLTitle.png"]];
    [_logoImage setImage:titleImage];

    // Set close icon image
    UIImage *closeImage = [UIImage imageNamed:[FBLBundleStore resourceNamed:@"closeWindow.png"]];
    [_closeButton setBackgroundImage:closeImage forState:UIControlStateNormal];

    // Set selected close state images
    UIImage *closeImageSelected = [UIImage imageNamed:[FBLBundleStore resourceNamed:@"closeWindowSelected.png"]];
    [_closeButton setBackgroundImage:closeImageSelected forState:UIControlStateHighlighted];
    [_closeButton setBackgroundImage:closeImageSelected forState:UIControlStateSelected];
}

-(void)toggleGlobalNotifcation:(NSNotification *)paramNotification {
    NSString *error = paramNotification.userInfo[@"error"];
    UIColor *color = paramNotification.userInfo[@"color"];
    [_errorMessage setBackgroundColor:color];

    float displacement = _errorMessage.frame.size.height;
    [_errorLabel setText:error];
    CGRect frameStart = _errorMessage.frame;
//
    CGRect frame1 = CGRectMake(frameStart.origin.x,
                               frameStart.origin.y + displacement,
                               frameStart.size.width,
                               frameStart.size.height);

    CGRect frame2 = CGRectMake(frameStart.origin.x,
                               frame1.origin.y - displacement,
                               frameStart.size.width,
                               frameStart.size.height);


    [UIView animateKeyframesWithDuration:2.0
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut animations:^{
                                     [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.2 animations:^{
                                         _errorMessage.frame = frame1;
                                     }];
                                     [UIView addKeyframeWithRelativeStartTime:1.5 relativeDuration:0.2 animations:^{
                                         _errorMessage.frame = frame2;
                                     }];
                                 } completion:nil];
}

- (IBAction)closeWindow:(id)sender {
    [_chatViewController hideFeedbackLoopWindow];
}

#pragma mark - Notification Center

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
