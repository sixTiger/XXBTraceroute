//
//  XXBTraceRouteQueue.m
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/4/17.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "XXBTraceRouteQueue.h"

@implementation XXBTraceRouteQueue
- (instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"XXB.Traceroute.%@", self] UTF8String], NULL);
    }
    return self;
}

@end
