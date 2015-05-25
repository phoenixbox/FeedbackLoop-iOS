//
//  FBLUser.m
//  FeedbackLoop
//
//  Created by Shane Rogers on 5/24/15.
//  Copyright (c) 2015 FBL. All rights reserved.
//

#import "FBLUser.h"

@implementation FBLUser

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

+(JSONKeyMapper*)keyMapper {
    return [[JSONKeyMapper alloc] initWithDictionary:@{
                                                       @"app_id": @"appid",
                                                       @"email": @"email",
                                                       @"user_name": @"userName",
                                                       @"created_at": @"createdAt",
                                                       @"links": @"links"
                                                       }];
}


@end
