//
//  FBLUser.h
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/24/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JSONModel.h"

@protocol FBLUser @end

@interface FBLUser : JSONModel

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *createdAt;
@property (nonatomic, strong) NSDictionary *links; // Any custom attrs to track

@end