//
//  XXBTracerouteRecord.h
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/7.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXBTracerouteRecord : NSObject

/**
 当前这一跳的IP
 */
@property (nonatomic) NSString *ip;

/**
 每次的往返耗时
 */
@property (nonatomic) NSArray<NSNumber *> *recvDurations;

/**
 次数
 */
@property (nonatomic) NSInteger total;

/**
 当前的TTL
 */
@property (nonatomic) NSInteger ttl;

@property(nonatomic, copy) NSString  *consumerMessage;

- (NSString *)getMessage;
@end
