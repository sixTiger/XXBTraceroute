//
//  XXBTracerouteProtocol.h
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/7.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXBTracerouteRecord.h"
@class XXBTracerouteUtil;

/**
 Traceroute中每一跳的结果回调
 
 @param record 记录结果的对象
 */
typedef void (^XXBTracerouteStepCallback)(XXBTracerouteRecord *record);
/**
 Traceroute结束的回调
 
 @param results 所有的结果
 @param succeed 是否成功
 */
typedef void (^XXBTracerouteFinishCallback)(NSArray<XXBTracerouteRecord *> *results, BOOL succeed);

@protocol XXBTracerouteProtocol <NSObject>

/**
 路由诊断回调

 @param tracerouteUtil 诊断的 XXBTracerouteUtil
 @param record 回调
 */
- (void)tracerouteUtil:(XXBTracerouteUtil *)tracerouteUtil stepCallback:(XXBTracerouteRecord *)record;

/**
 路由诊断回调
 
 @param tracerouteUtil 诊断的 XXBTracerouteUtil
 @param records 回调
 @param succsee 诊断是否成功
 */
- (void)tracerouteUtil:(XXBTracerouteUtil *)tracerouteUtil finishCallback:(NSArray<XXBTracerouteRecord *> *)records success:(BOOL)succsee;

@end
