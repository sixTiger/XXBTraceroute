//
//  XXBTracerouteAddress.m
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/8.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "XXBTracerouteAddress.h"
#include <netdb.h>
#include <arpa/inet.h>

NSString *const kXXBTracerouteAddressV4  =   @"kXXBTracerouteAddressV4";
NSString *const kXXBTracerouteAddressV6  =   @"kXXBTracerouteAddressV6";

@implementation XXBTracerouteAddress
+ (NSDictionary *)getDNSsWithDormain:(NSString *)hostName {
    NSMutableArray *addresses_v4 = [NSMutableArray array];
    NSMutableArray *addresses_v6 = [NSMutableArray array];
    
    NSError *error = nil;
    struct addrinfo hints, *res, *res0;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    
    int getaddrinfo_result = getaddrinfo([hostName UTF8String], NULL, &hints, &res0);
    
    if (getaddrinfo_result != noErr) {
        error = [self getErrorWith:getaddrinfo_result];
        //获取地址失败
    } else {
        for (res = res0; res; res = res->ai_next) {
            if (res->ai_family == AF_INET) {
                char host[NI_MAXHOST];
                memset(host, 0, NI_MAXHOST);
                getnameinfo(res->ai_addr, res->ai_addrlen, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
                if (strlen(host) != 0) {
                    [addresses_v4 addObject:[NSString stringWithUTF8String:host]];
                }
            } else if (res->ai_family == AF_INET6) {
                
                char host[NI_MAXHOST];
                memset(host, 0, NI_MAXHOST);
                getnameinfo(res->ai_addr, res->ai_addrlen, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
                if (strlen(host) != 0) {
                    [addresses_v6 addObject:[NSString stringWithUTF8String:host]];
                }
                
            }
        }
        freeaddrinfo(res0);
    }
    return @{
             kXXBTracerouteAddressV4:addresses_v4,
             kXXBTracerouteAddressV6:addresses_v6
             } ;
}


+ (NSArray *)getIPV4DNSWithHostName:(NSString *)hostName {
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    
    @try {
        phot = gethostbyname(hostN);
    } @catch (NSException *exception) {
        return nil;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in_addr ip_addr;
        memcpy(&ip_addr, phot->h_addr_list[j], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        
        NSString *strIPAddress = [NSString stringWithUTF8String:ip];
        [result addObject:strIPAddress];
        j++;
    }
    
    return [NSArray arrayWithArray:result];
}


+ (NSArray *)getIPV6DNSWithHostName:(NSString *)hostName {
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    
    @try {
        /**
         * 只有在IPV6的网络下才会有返回值
         */
        phot = gethostbyname2(hostN, AF_INET6);
    } @catch (NSException *exception) {
        return nil;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in6_addr ip6_addr;
        memcpy(&ip6_addr, phot->h_addr_list[j], sizeof(struct in6_addr));
        NSString *strIPAddress = [self formatIPV6Address: ip6_addr];
        [result addObject:strIPAddress];
        j++;
    }
    return [NSArray arrayWithArray:result];
}

+(NSString *)formatIPV6Address:(struct in6_addr)ipv6Addr{
    NSString *address = nil;
    
    char dstStr[INET6_ADDRSTRLEN];
    char srcStr[INET6_ADDRSTRLEN];
    memcpy(srcStr, &ipv6Addr, sizeof(struct in6_addr));
    if(inet_ntop(AF_INET6, srcStr, dstStr, INET6_ADDRSTRLEN) != NULL){
        address = [NSString stringWithUTF8String:dstStr];
    }
    return address;
}

+ (NSError *)getErrorWith:(int)getAddrinfo_result {
    NSString *errMsg = [NSString stringWithCString:gai_strerror(getAddrinfo_result) encoding:NSASCIIStringEncoding];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"kCFStreamErrorDomainNetDB" code:getAddrinfo_result userInfo:userInfo];
}
@end
