//
//  FBLSlackStore.h
//  Stndout
//
//  Created by Shane Rogers on 4/19/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import <Foundation/Foundation.h>

// Data Layer
#import "FBLChatCollection.h"

@interface FBLSlackStore : NSObject

@property (nonatomic, strong) NSString *webhookUrl;
@property (nonatomic, strong) NSString *userChannelId;

+ (FBLSlackStore *)sharedStore;

- (void)setupWebhook:(void (^)(NSError *err))block;

- (void)feedbackLoopAuth:(void (^)(FBLChatCollection *chatHistory, NSError *err))block;

- (void)joinOrCreateChannel:(void (^)(NSError *err))block;

@end
