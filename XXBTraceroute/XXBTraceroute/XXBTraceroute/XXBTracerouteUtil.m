//
//  XXBTracerouteUtil.m
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/4/17.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "XXBTracerouteUtil.h"
#import <UIKit/UIKit.h>
#import "XXBTracerouteCommon.h"
#import "XXBTracerouteAddress.h"

@interface XXBTracerouteUtil()
/**
 app进入后台需结束这次Traceroute
 */
@property(nonatomic, assign) BOOL                               shouEndThisTraceroute;
@property(nonatomic, strong) NSLock                             *lock;
@property(nonatomic, strong) XXBTracerouteContext               *tracerouteContext;
@property (nonatomic) NSMutableArray<XXBTracerouteRecord *>     *results;
@end
@implementation XXBTracerouteUtil

- (instancetype)init {
    if (self = [super init]) {
        _lock = [[NSLock alloc] init];
        [self addNotification];
    }
    return self;
}
#pragma mark - Traceroute
/**
 开始路由诊断
 
 @param tracerouteContext 诊断的context
 */
- (void)startTracerouteWithContext:(XXBTracerouteContext *)tracerouteContext {
    _tracerouteContext = tracerouteContext;
    _results = [NSMutableArray array];
    BOOL isIPv6 = NO;
    NSString *ipAddress = nil;
    if (isEmpty_XXBTR(tracerouteContext.ip)) {
        NSDictionary *ipAddressDict = [XXBTracerouteAddress getDNSsWithDormain:tracerouteContext.host];
        switch (tracerouteContext.tracerouteType) {
            case XXBTracerouteTypeAny:
            {
                isIPv6 = YES;
                ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV6] firstObject];
                if (isEmpty_XXBTR(ipAddress)) {
                    ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV4] firstObject];
                    isIPv6 = NO;
                }
                break;
            }
            case XXBTracerouteTypeIPV4only:
            {
                isIPv6 = NO;
                ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV4] firstObject];
                break;
            }
            case XXBTracerouteTypeIPV4First:
            {
                isIPv6 = NO;
                ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV4] firstObject];
                if (isEmpty_XXBTR(ipAddress)) {
                    ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV6] firstObject];
                    isIPv6 = YES;
                }
                break;
            }
            case XXBTracerouteTypeIPV6only:
            {
                isIPv6 = YES;
                ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV6] firstObject];
                break;
            }
            case XXBTracerouteTypeIPV6First:
            {
                isIPv6 = YES;
                ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV6] firstObject];
                if (isEmpty_XXBTR(ipAddress)) {
                    ipAddress = [[ipAddressDict valueForKey:kXXBTracerouteAddressV4] firstObject];
                    isIPv6 = NO;
                }
                break;
            }
            default:
                break;
        }
    }
    tracerouteContext.ip = ipAddress;
    tracerouteContext.isIPV6 = isIPv6;
    if (isEmpty_XXBTR(ipAddress)) {
        if (tracerouteContext.finishaCallBack) {
            tracerouteContext.finishaCallBack(@[], NO);
        }
        if ([tracerouteContext.delegate respondsToSelector:@selector(tracerouteUtil:finishCallback:success:)]) {
            [tracerouteContext.delegate tracerouteUtil:self finishCallback:@[] success:NO];
        }
        return;
    }
    // 目标主机地址
    struct sockaddr *remoteAddr = [XXBTracerouteCommon makeSockaddrWithAddress:ipAddress
                                                                          port:(int)kTraceRoutePort
                                                                        isIPv6:isIPv6];
    
    if (remoteAddr == NULL) {
        if (tracerouteContext.finishaCallBack) {
            tracerouteContext.finishaCallBack(@[], NO);
        }
        if ([tracerouteContext.delegate respondsToSelector:@selector(tracerouteUtil:finishCallback:success:)]) {
            [tracerouteContext.delegate tracerouteUtil:self finishCallback:@[] success:NO];
        }
        return;
    }
    
    // 创建套接字
    int send_sock;
    if ((send_sock = socket(remoteAddr->sa_family,
                            SOCK_DGRAM,
                            isIPv6 ? IPPROTO_ICMPV6 : IPPROTO_ICMP)) < 0) {
        if (tracerouteContext.finishaCallBack) {
            tracerouteContext.finishaCallBack(@[], NO);
        }
        if ([tracerouteContext.delegate respondsToSelector:@selector(tracerouteUtil:finishCallback:success:)]) {
            [tracerouteContext.delegate tracerouteUtil:self finishCallback:@[] success:NO];
        }
        return;
    }
    
    //traceroute to weibo.com (123.125.104.197), 64 hops max, 52 byte packets
    XXBTracerouteRecord *record = [[XXBTracerouteRecord alloc] init];
    record.consumerMessage = [NSString stringWithFormat:@"traceroute\tto\t%@\t(%@),\t%d\thops\tmax,\t52\tbyte\tpackets",tracerouteContext.host, tracerouteContext.ip, tracerouteContext.maxTtl];
    [_results addObject:record];
    
    if (tracerouteContext.stepCallback) {
        tracerouteContext.stepCallback(record);
    }
    if ([tracerouteContext.delegate respondsToSelector:@selector(tracerouteUtil:stepCallback:)]) {
        [tracerouteContext.delegate tracerouteUtil:self stepCallback:record];
    }
    
    // 超时时间3秒
    struct timeval timeout;
    timeout.tv_sec = tracerouteContext.stepTimeout;
    timeout.tv_usec = 0;
    setsockopt(send_sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
    
    //后台发送的情况下不 SIGPIPE 信号
    int value = 1;
    setsockopt(send_sock, SOL_SOCKET, SO_NOSIGPIPE, &value, sizeof(value));
    
    int ttl = 1;
    BOOL succeed = NO;
    do {
        [_lock lock];
        if (self.shouEndThisTraceroute) {
            [_lock unlock];
            break;
        }
        [_lock unlock];;
        
        // 设置数据包TTL，依次递增
        if (setsockopt(send_sock,
                       isIPv6 ? IPPROTO_IPV6 : IPPROTO_IP,
                       isIPv6 ? IPV6_UNICAST_HOPS : IP_TTL,
                       &ttl,
                       sizeof(ttl)) < 0) {
        }
        succeed = [self sendAndRecv:send_sock addr:remoteAddr ttl:ttl];
    } while (++ttl <= tracerouteContext.maxTtl && !succeed);
    
    close(send_sock);
    
    // traceroute结束，回调结果
    if (tracerouteContext.finishaCallBack) {
        tracerouteContext.finishaCallBack(self.results, succeed);
    }
    if ([tracerouteContext.delegate respondsToSelector:@selector(tracerouteUtil:finishCallback:success:)]) {
        [tracerouteContext.delegate tracerouteUtil:self finishCallback:self.results success:succeed];
    }
}

/**
 向指定目标连续发送3个数据包
 
 @param sendSock 发送用的socket
 @param addr     地址
 @param ttl      TTL大小
 @return 如果找到目标服务器则返回YES，否则返回NO
 */
- (BOOL)sendAndRecv:(int)sendSock addr:(struct sockaddr *)addr ttl:(int)ttl {
    char buff[200];
    BOOL finished = NO;
    XXBTracerouteContext *context = self.tracerouteContext;
    BOOL isIPv6 = context.isIPV6;
    NSString *ipAddress = context.ip;
    
    socklen_t addrLen = isIPv6 ? sizeof(struct sockaddr_in6) : sizeof(struct sockaddr_in);
    
    // 构建icmp报文
    uint16_t identifier = (uint16_t)ttl;
    NSData *packetData = [XXBTracerouteCommon makeICMPPacketWithID:identifier sequence:ttl isICMPv6:isIPv6];
    
    // 记录结果
    XXBTracerouteRecord *record = [[XXBTracerouteRecord alloc] init];
    record.ttl = ttl;
    
    BOOL receiveReply = NO;
    NSMutableArray *durations = [[NSMutableArray alloc] init];
    
    // 连续发送3个ICMP报文，记录往返时长
    for (int try = 0; try < context.stepMaxAttempts; try ++) {
        [_lock lock];
        if (self.shouEndThisTraceroute) {
            [_lock unlock];
            break;
        }
        [_lock unlock];
        NSDate* startTime = [NSDate date];
        // 发送icmp报文
        ssize_t sent = sendto(sendSock,
                              packetData.bytes,
                              packetData.length,
                              0,
                              addr,
                              addrLen);
        if (sent < 0) {
            [durations addObject:[NSNull null]];
            continue;
        }
        
        // 接收icmp数据
        struct sockaddr_storage remoteAddr;
        ssize_t resultLen = recvfrom(sendSock, buff, sizeof(buff), 0, (struct sockaddr*)&remoteAddr, &addrLen);
        if (resultLen < 0) {
            // fail
            [durations addObject:[NSNull null]];
            continue;
        } else {
            receiveReply = YES;
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
            
            // 解析IP地址
            NSString* remoteAddress = nil;
            if (!isIPv6) {
                char ip[INET_ADDRSTRLEN] = {0};
                inet_ntop(AF_INET, &((struct sockaddr_in *)&remoteAddr)->sin_addr.s_addr, ip, sizeof(ip));
                remoteAddress = [NSString stringWithUTF8String:ip];
            } else {
                char ip[INET6_ADDRSTRLEN] = {0};
                inet_ntop(AF_INET6, &((struct sockaddr_in6 *)&remoteAddr)->sin6_addr, ip, INET6_ADDRSTRLEN);
                remoteAddress = [NSString stringWithUTF8String:ip];
            }
            
            // 结果判断
            if ([XXBTracerouteCommon isTimeoutPacket:buff len:(int)resultLen isIPv6:isIPv6]) {
                // 到达中间节点
                [durations addObject:@(duration)];
                record.ip = remoteAddress;
            } else if ([XXBTracerouteCommon isEchoReplyPacket:buff len:(int)resultLen isIPv6:isIPv6]) {
                if ([remoteAddress isEqualToString:ipAddress]) {
                    // 到达目标服务器
                    [durations addObject:@(duration)];
                    record.ip = remoteAddress;
                    finished = YES;
                } else {
                    // 到达中间节点(某些节点发送的豹纹有问题)
                    [durations addObject:@(duration)];
                    record.ip = remoteAddress;
                }
            } else {
                // 失败
                [durations addObject:[NSNull null]];
            }
        }
    }
    record.recvDurations = [durations copy];
    [_results addObject:record];
    
    // 回调每一步的结果
    if (context.stepCallback) {
        context.stepCallback(record);
    }
    if ([context.delegate respondsToSelector:@selector(tracerouteUtil:stepCallback:)]) {
        [context.delegate tracerouteUtil:self stepCallback:record];
    }
    return finished;
}


#pragma mark - NSNotification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDdidEnterDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addDdidEnterDidEnterBackground:(NSNotification *)notification {
    [_lock lock];
    self.shouEndThisTraceroute = YES;
    [_lock unlock];
}
@end
