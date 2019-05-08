//
//  XXBTracerouteAddress.h
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/8.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kXXBTracerouteAddressV4;
extern NSString *const kXXBTracerouteAddressV6;

@interface XXBTracerouteAddress : NSObject

/**
 获取域名的IPV6地址
 
 @param hostName 域名
 @return ip地址
 */
+ (NSArray *)getIPV6DNSWithHostName:(NSString *)hostName;

/**
 获取域名的IPV4地址
 
 @param hostName 域名
 @return ip地址
 */
+ (NSArray *)getIPV4DNSWithHostName:(NSString *)hostName;

/*
 * 通过域名获取服务器DNS地址
 extern NSString *const kSimaGetAddressV4;
 extern NSString *const kSimaGetAddressV6;
 */
+ (NSDictionary *)getDNSsWithDormain:(NSString *)hostName;
@end
