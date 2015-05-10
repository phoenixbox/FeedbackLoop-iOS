//
//  FBLChatCollection.m
//  Stndout
//
//  Created by Shane Rogers on 4/18/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import "FBLChatCollection.h"
#import "FBLChat.h"

@implementation FBLChatCollection

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (void)loadMediaForMessages {
    for (FBLChat* chat in _messages) {
        if (chat.isMedia) {
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
                    } else {
                        NSLog(@"Chat image not downloaded. Nothing to display.");
                    }
                });
            });
        }
    }
}

@end
