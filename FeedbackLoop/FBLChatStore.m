//
//  FBLMessageStore.m
//  Stndout
//
//  Created by Shane Rogers on 4/18/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import "FBLChatStore.h"

#import "FBLAppConstants.h"
#import "FBLAuthenticationStore.h"

// Libs
#import "AFNetworking.h"

@implementation FBLChatStore

+ (FBLChatStore *)sharedStore {
    static FBLChatStore *chatStore = nil;

    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        chatStore = [[FBLChatStore alloc] init];
    });

    return chatStore;
}

//    Chat Error Description
//    --------------------------------------------------------------
//    channel_not_found: Value passed for channel was invalid.
//    not_in_channel: Cannot post user messages to a channel they are not in.
//    is_archived: Channel has been archived.
//    msg_too_long: Message text is too long
//    no_text: No message text provided
//    rate_limited: Application has posted too many messages, read the Rate Limit documentation for more information
//    not_authed: No authentication token provided.
//    invalid_auth: Invalid authentication token.
//    account_inactive: Authentication token is for a deleted user or team.

//    Chat Scheme
//    --------------------------------------------------------------
//{
//    "ok": true,
//    "ts": "1405895017.000506",
//    "channel": "C024BE91L",
//    "message": {
//        …
//    }
//}

- (void)sendSlackMessage:(NSString *)message toChannel:(FBLChannel *)channel withCompletion:(void (^)(FBLChat *chat, NSString *error))block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        NSString *requestURL = [[FBLAuthenticationStore sharedInstance] oauthRequest:SLACK_API_BASE_URL withURLSegment:SLACK_API_MESSAGE_POST];
//    NSString *requestURL = authenticateRequestWithURLSegment(SLACK_API_BASE_URL, SLACK_API_MESSAGE_POST);

    // TODO: FBLUser Helpers: Fallback for when there is no user email etc.
//    NSString *messageParam = [NSString stringWithFormat:@"&text=%@",message];
//    requestURL = [requestURL stringByAppendingString:messageParam];
    NSString *channelIdParam = [NSString stringWithFormat:@"&channel=%@",channel.id];
    requestURL = [requestURL stringByAppendingString:channelIdParam];

    NSDictionary *textParams = @{@"text": message};

    [manager POST:requestURL parameters:textParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary *sendMessageResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];

        NSNumber *ok = [sendMessageResponse objectForKey:@"ok"];
        if ([ok isEqual:@(YES)]) {
            FBLChat *chat = [[FBLChat alloc] initWithDictionary:[sendMessageResponse objectForKey:@"message"] error:nil];

            block(chat, nil);
        } else {
            NSString *errorType = [sendMessageResponse objectForKey:@"error"];

            block(nil, errorType);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        block(nil, error.localizedDescription);
    }];
}

// Required Scheme by the /api/messages endpoint
//    user: {
//      app_id:,
//      user_name:,
//      user_link:,
//      email:
//    },
//    message: {
//      token:
//      channel:
//      text:
//    }

- (void)sendMessageToAPI:(NSString *)message toChannel:(FBLChannel *)channel withCompletion:(void (^)(FBLChat *chat, NSString *error))block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    FBLAuthenticationStore *authStore = [FBLAuthenticationStore sharedInstance];

    NSString *base = PROD_API_BASE_URL;
// Reassign for local development
#ifdef DEBUG
    base = DEV_API_BASE_URL;
#endif

    // What params does the api expect
    NSString *requestURL = [[FBLAuthenticationStore sharedInstance] oauthRequest:DEV_API_BASE_URL withURLSegment:DEV_API_MESSAGES];

    NSString *channelIdParam = [NSString stringWithFormat:@"&channel=%@",channel.id];
    requestURL = [requestURL stringByAppendingString:channelIdParam];

    NSDictionary *userParams = [self userMessageParams];
    NSDictionary *messageParams = @{
                                 @"text": message,
                                 @"user": @{
                                            @"app_id": authStore.AppId,
                                            @"email": [userParams objectForKey:@"email"],
                                            @"user_name": [userParams objectForKey:@"username"],
                                            @"user_link": [userParams objectForKey:@"links"],
                                        },
                                 @"message": @{
                                         @"token": authStore.slackToken,
                                         @"channel": channel.id,
                                         @"text": message,
                                         @"username": [userParams objectForKey:@"username"]
                                 }
                                };


    [manager POST:requestURL parameters:messageParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary *sendMessageResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];

        NSNumber *ok = [sendMessageResponse objectForKey:@"ok"];
        if ([ok isEqual:@(YES)]) {
            FBLChat *chat = [[FBLChat alloc] initWithDictionary:[sendMessageResponse objectForKey:@"message"] error:nil];

            block(chat, nil);
        } else {
            NSString *errorType = [sendMessageResponse objectForKey:@"error"];

            block(nil, errorType);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        block(nil, error.localizedDescription);
    }];
}

- (NSDictionary *)userMessageParams {
    FBLAuthenticationStore *authStore = [FBLAuthenticationStore sharedInstance];
    NSString *username;
    NSDictionary *links;
    NSString *email;

    if (authStore.user == nil) {
        username = authStore.userEmail;
        links = @{};
        email = authStore.userEmail;
    } else {
        username = authStore.user.userName;
        links = authStore.user.links;
        email = authStore.user.email;
    }

    return @{
             @"username": username,
             @"links": links,
             @"email": email
             };
}

//token	xxxx-xxxxxxxxx-xxxx	Required
//Authentication token (Requires scope: post)
//file	...	Optional
//File contents via multipart/form-data.
//content	...	Optional
//File contents via a POST var.
//filetype	php	Optional
//Slack-internal file type identifier.
//filename	foo.txt	Optional
//Filename of file.
//title	My File	Optional
//Title of file.
//initial_comment	Best!	Optional
//Initial comment to add to file.
//channels	C1234567890

- (void)sendSlackImage:(UIImage *)image toChannel:(FBLChannel *)channel withCompletion:(void (^)(FBLChat *chat, NSString *))block {

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSString *requestURL = [[FBLAuthenticationStore sharedInstance] oauthRequest:SLACK_API_BASE_URL withURLSegment:SLACK_API_FILE_POST];

    NSString *channelIdParam = [NSString stringWithFormat:@"&channels=%@",channel.id];
    requestURL = [requestURL stringByAppendingString:channelIdParam];

    [manager POST:requestURL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        // 'Name' is the param name to use
        [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 1.0) name:@"file" fileName:@"burner.jpg" mimeType:@"image/jpeg"];

    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success: %@", responseObject);
        NSMutableDictionary *sendMessageResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];

        NSNumber *ok = [sendMessageResponse objectForKey:@"ok"];
        if ([ok isEqual:@(YES)]) {
            FBLChat *chat = [[FBLChat alloc] initWithDictionary:[sendMessageResponse objectForKey:@"message"] error:nil];

            block(chat, nil);
        } else {
            NSString *errorType = [sendMessageResponse objectForKey:@"error"];

            block(nil, errorType);
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(nil, error.localizedDescription);
    }];
}

- (void)fetchHistoryForChannel:(NSString *)channelId withCompletion:(void (^)(FBLChatCollection *chatCollection, NSString *))block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSString *requestURL = [[FBLAuthenticationStore sharedInstance] oauthRequest:SLACK_API_BASE_URL withURLSegment:SLACK_API_CHANNEL_HISTORY];
    // TODO: FBLUser Helpers: Fallback for when there is no user email etc.

    NSString *channelIdParam = [NSString stringWithFormat:@"&channel=%@",channelId];
    requestURL = [requestURL stringByAppendingString:channelIdParam];

    [manager POST:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary *sendMessageResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];

        NSNumber *ok = [sendMessageResponse objectForKey:@"ok"];
        if ([ok isEqual:@(YES)]) {
            NSString *rawJSON = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

            FBLChatCollection *chatCollection = [[FBLChatCollection alloc] initWithString:rawJSON error:nil];
            [chatCollection loadMediaForMessages];

            block(chatCollection, nil);
        } else {
            NSString *errorType = [sendMessageResponse objectForKey:@"error"];

            block(nil, errorType);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        block(nil, error.localizedDescription);
    }];
}

// TODO: This whole file needs correct NSError objects passed back for failure states

- (void)fetchImageForChat:(FBLChat *)chat withCompletion:(void (^)(UIImage *image, NSString *error))block {
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(concurrentQueue, ^{
        __block UIImage *image = nil;

        dispatch_sync(concurrentQueue, ^{
            NSURL *url = [NSURL URLWithString:chat.imgUrl];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
            NSError *downloadError = nil;
            NSData *imageData = [NSURLConnection sendSynchronousRequest:urlRequest
                                                      returningResponse:nil
                                                                  error:&downloadError];

            if (downloadError == nil && imageData != nil){
                NSLog(@"Chat image data received.");
                image = [UIImage imageWithData:imageData];
            } else if (downloadError != nil){
                NSLog(@"Error happened = %@", downloadError); } else {
                    NSLog(@"Couldnt get any data for that chat's img url");
                }
        });

        dispatch_sync(dispatch_get_main_queue(), ^{
            if (image != nil){
                NSLog(@"Chat image downloaded.");
                chat.img = image;
                block(image, nil);
            } else {
                block(nil, @"Chat image not downloaded. Nothing to display.");
                NSLog(@"Chat image not downloaded. Nothing to display.");
            }
        });
    });

}

@end
