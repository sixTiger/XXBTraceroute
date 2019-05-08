//
//  XXBTracerouteUtil.h
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/4/17.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXBTracerouteContext.h"

@interface XXBTracerouteUtil : NSObject

/**
 当前网络诊断的上下文信息
 */
@property(nonatomic, strong, readonly) XXBTracerouteContext    *tracerouteContext;

/**
 开始路由诊断

 @param tracerouteContext 诊断的context
 */
- (void)startTracerouteWithContext:(XXBTracerouteContext *)tracerouteContext;
@end
