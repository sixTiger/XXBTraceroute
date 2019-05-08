//
//  XXBTraceRouteQueue.h
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/4/17.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXBTracerouteUtil.h"

@interface XXBTraceRouteQueue : NSObject{
    dispatch_queue_t    _queue;
    XXBTracerouteUtil   *_tracerouteUtil;
}

+ (instancetype)traceRouteQueue;

/**
 开始网络诊断

 @param block 网络诊断的回调
 */
- (void)inTraceRoute:(void (^)(XXBTracerouteUtil *tracerouteUtil))block;

@end

