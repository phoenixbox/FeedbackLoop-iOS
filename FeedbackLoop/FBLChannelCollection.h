//
//  FBLChannelCollection.h
//  Stndout
//
//  Created by Shane Rogers on 4/18/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBLChannel.h"
#import "JSONModel.h"

@interface FBLChannelCollection : JSONModel

@property (strong, nonatomic) NSMutableArray<FBLChannel> *channels;

@end