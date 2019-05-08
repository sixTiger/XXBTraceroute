//
//  XXBTracerouteContext.h
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/7.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXBTracerouteProtocol.h"

#define XXBTracerouteContextMaxTtl_DEF 64
#define XXBTracerouteContextStepMaxAttempts_DEF 3
#define XXBTracerouteContextStepTimeout_DEF 5

typedef enum : NSUInteger {
    XXBTracerouteTypeAny,//效果和 XXBTracerouteTypeIPV6First 一样
    XXBTracerouteTypeIPV4only,
    XXBTracerouteTypeIPV4First,
    XXBTracerouteTypeIPV6only,
    XXBTracerouteTypeIPV6First,
} XXBTracerouteType;

@interface XXBTracerouteContext : NSObject

/**
 需要诊断的类型 默认 XXBTracerouteTypeAny
 */
@property(nonatomic, assign) XXBTracerouteType  tracerouteType;

/**
 host
 */
@property(nonatomic, copy) NSString                         *host;

/**
 需要诊断的ip信息 有IP的情况下优先使用IP，没有IP的情况下会拿着host去获取IP
 */
@property(nonatomic, copy) NSString                         *ip;

/**
 是否是IPV6地址
 */
@property(nonatomic, assign) BOOL                           isIPV6;

/**
 最大跳数 默认值64
 */
@property(nonatomic, assign) int                            maxTtl;

/**
 每一跳尝试次数 默认值3
 */
@property(nonatomic, assign) int                            stepMaxAttempts;

/**
 每一跳的超时时长 默认5s
 */
@property(nonatomic, assign) int                            stepTimeout;

/**
 诊断每一步的回调 
 */
@property(nonatomic, copy) XXBTracerouteStepCallback        stepCallback;

/**
 诊断完成的回调
 */
@property(nonatomic, copy) XXBTracerouteFinishCallback      finishaCallBack;

/**
 网络诊断相关的回调
 */
@property(nonatomic, weak) id<XXBTracerouteProtocol>        delegate;

+ (instancetype)defaultContext;
@end
