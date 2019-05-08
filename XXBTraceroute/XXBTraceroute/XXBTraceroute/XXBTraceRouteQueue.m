//
//  XXBTraceRouteQueue.m
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/4/17.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "XXBTraceRouteQueue.h"

@interface XXBTraceRouteQueue()
@property(nonatomic, strong) dispatch_queue_t       queue;
@property(nonatomic, strong) XXBTracerouteUtil      *tracerouteUtil;
@end

@implementation XXBTraceRouteQueue

+ (instancetype)traceRouteQueue {
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"XXB.Traceroute.%@", self] UTF8String], NULL);
        _tracerouteUtil = [[XXBTracerouteUtil alloc] init];
    }
    return self;
}

/**
 开始网络诊断
 
 @param block 网络诊断的回调
 */
- (void)inTraceRoute:(void (^)(XXBTracerouteUtil *tracerouteUtil))block {
    dispatch_async(self.queue, ^{
        block(self.tracerouteUtil);
    });
}
@end
