//
//  XXBTracerouteCommon.m
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/8.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "XXBTracerouteCommon.h"
#import <AssertMacros.h>

extern BOOL isEmpty_XXBTR(id value) {
    if (value == nil) return YES;
    if ([value isKindOfClass:[NSNull class]]) return YES;
    if ([value isKindOfClass:[NSString class]]) return [value length] == 0;
    return NO;
}


// IPv4数据报结构
typedef struct IPv4Header {
    uint8_t versionAndHeaderLength; // 版本和首部长度
    uint8_t serviceType; // 服务类型
    uint16_t totalLength; // 数据包长度
    uint16_t identifier;
    uint16_t flagsAndFragmentOffset;
    uint8_t timeToLive;
    uint8_t protocol; // 协议类型，1表示ICMP: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    uint16_t checksum;
    uint8_t sourceAddress[4];
    uint8_t destAddress[4];
    // options...
    // data...
} IPv4Header;

// IPv4Header编译期检查
__Check_Compile_Time(sizeof(IPv4Header) == 20);
__Check_Compile_Time(offsetof(IPv4Header, versionAndHeaderLength) == 0);
__Check_Compile_Time(offsetof(IPv4Header, serviceType) == 1);
__Check_Compile_Time(offsetof(IPv4Header, totalLength) == 2);
__Check_Compile_Time(offsetof(IPv4Header, identifier) == 4);
__Check_Compile_Time(offsetof(IPv4Header, flagsAndFragmentOffset) == 6);
__Check_Compile_Time(offsetof(IPv4Header, timeToLive) == 8);
__Check_Compile_Time(offsetof(IPv4Header, protocol) == 9);
__Check_Compile_Time(offsetof(IPv4Header, checksum) == 10);
__Check_Compile_Time(offsetof(IPv4Header, sourceAddress) == 12);
__Check_Compile_Time(offsetof(IPv4Header, destAddress) == 16);
__Check_Compile_Time(sizeof(ICMPPacket) == 8);
__Check_Compile_Time(offsetof(ICMPPacket, type) == 0);
__Check_Compile_Time(offsetof(ICMPPacket, code) == 1);
__Check_Compile_Time(offsetof(ICMPPacket, checksum) == 2);
__Check_Compile_Time(offsetof(ICMPPacket, identifier) == 4);
__Check_Compile_Time(offsetof(ICMPPacket, sequenceNumber) == 6);

@implementation XXBTracerouteCommon

// 来源于官方示例：https://developer.apple.com/library/content/samplecode/SimplePing/Introduction/Intro.html
+ (uint16_t)makeChecksumFor:(const void *)buffer len:(size_t)bufferLen {
    size_t bytesLeft;
    int32_t sum;
    const uint16_t *cursor;
    union {
        uint16_t us;
        uint8_t uc[2];
    } last;
    uint16_t answer;
    
    bytesLeft = bufferLen;
    sum = 0;
    cursor = buffer;
    
    /*
     * Our algorithm is simple, using a 32 bit accumulator (sum), we add
     * sequential 16 bit words to it, and at the end, fold back all the
     * carry bits from the top 16 bits into the lower 16 bits.
     */
    while (bytesLeft > 1) {
        sum += *cursor;
        cursor += 1;
        bytesLeft -= 2;
    }
    
    /* mop up an odd byte, if necessary */
    if (bytesLeft == 1) {
        last.uc[0] = *(const uint8_t *)cursor;
        last.uc[1] = 0;
        sum += last.us;
    }
    
    /* add back carry outs from top 16 bits to low 16 bits */
    sum = (sum >> 16) + (sum & 0xffff); /* add hi 16 to low 16 */
    sum += (sum >> 16); /* add carry */
    answer = (uint16_t)~sum; /* truncate to 16 bits */
    
    return answer;
}

+ (struct sockaddr *)makeSockaddrWithAddress:(NSString *)address port:(int)port isIPv6:(BOOL)isIPv6 {
    NSData *addrData = nil;
    if (isIPv6) {
        struct sockaddr_in6 addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin6_family = AF_INET6;
        addr.sin6_len = sizeof(addr);
        addr.sin6_port = htons(port);
        if (inet_pton(AF_INET6, address.UTF8String, &addr.sin6_addr) < 0) {
            return NULL;
        }
        addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
    } else {
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        if (inet_pton(AF_INET, address.UTF8String, &addr.sin_addr.s_addr) < 0) {
            return NULL;
        }
        addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
    }
    return (struct sockaddr *)[addrData bytes];
}

+ (NSData *)makeICMPPacketWithID:(uint16_t)identifier sequence:(uint16_t)seq isICMPv6:(BOOL)isICMPv6 {
    NSMutableData *packet;
    ICMPPacket *icmpPtr;
    
    packet = [NSMutableData dataWithLength:sizeof(*icmpPtr)];
    
    icmpPtr = packet.mutableBytes;
    icmpPtr->type = isICMPv6 ? kICMPv6TypeEchoRequest : kICMPv4TypeEchoRequest;
    icmpPtr->code = 0;
    icmpPtr->checksum = 0;
    icmpPtr->identifier     = OSSwapHostToBigInt16(identifier);
    icmpPtr->sequenceNumber = OSSwapHostToBigInt16(seq);
    // ICMPv6的校验和由内核计算
    if (!isICMPv6) {
        icmpPtr->checksum = [self makeChecksumFor:packet.bytes len:packet.length];
    }
    
    return packet;
}

+ (NSArray<NSString *> *)resolveHost:(NSString *)hostname {
    NSMutableArray<NSString *> *resolve = [NSMutableArray array];
    CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostname);
    if (hostRef != NULL) {
        Boolean result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL); // 开始DNS解析
        if (result == true) {
            CFArrayRef addresses = CFHostGetAddressing(hostRef, &result);
            for(int i = 0; i < CFArrayGetCount(addresses); i++){
                CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
                struct sockaddr *addressGeneric = (struct sockaddr *)CFDataGetBytePtr(saData);
                
                if (addressGeneric != NULL) {
                    if (addressGeneric->sa_family == AF_INET) {
                        struct sockaddr_in *remoteAddr = (struct sockaddr_in *)CFDataGetBytePtr(saData);
                        [resolve addObject:[self formatIPv4Address:remoteAddr->sin_addr]];
                    } else if (addressGeneric->sa_family == AF_INET6) {
                        struct sockaddr_in6 *remoteAddr = (struct sockaddr_in6 *)CFDataGetBytePtr(saData);
                        [resolve addObject:[self formatIPv6Address:remoteAddr->sin6_addr]];
                    }
                }
            }
        }
    }
    
    return [resolve copy];
}

+ (BOOL)isEchoReplyPacket:(char *)packet len:(int)len isIPv6:(BOOL)isIPv6{
    ICMPPacket *icmpPacket = NULL;
    if (isIPv6) {
        icmpPacket = [self unpackICMPv6Packet:packet len:len];
        if (icmpPacket != NULL && icmpPacket->type == kICMPv6TypeEchoReply) {
            return YES;
        }
    } else {
        icmpPacket = [self unpackICMPv4Packet:packet len:len];
        if (icmpPacket != NULL && icmpPacket->type == kICMPv4TypeEchoReply) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)isTimeoutPacket:(char *)packet len:(int)len isIPv6:(BOOL)isIPv6 {
    ICMPPacket *icmpPacket = NULL;
    if (isIPv6) {
        icmpPacket = [self unpackICMPv6Packet:packet len:len];
        if (icmpPacket != NULL && icmpPacket->type == kICMPv6TypeTimeOut) {
            return YES;
        }
    } else {
        icmpPacket = [self unpackICMPv4Packet:packet len:len];
        if (icmpPacket != NULL && icmpPacket->type == kICMPv4TypeTimeOut) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Helper

// 从IPv4数据包中解析出ICMP
+ (ICMPPacket *)unpackICMPv4Packet:(char *)packet len:(int)len {
    if (len < (sizeof(IPv4Header) + sizeof(ICMPPacket))) {
        return NULL;
    }
    const struct IPv4Header *ipPtr = (const IPv4Header *)packet;
    if ((ipPtr->versionAndHeaderLength & 0xF0) != 0x40 || // IPv4
        ipPtr->protocol != 1) { //ICMP
        return NULL;
    }
    
    size_t ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t); // IPv4头部长度
    if (len < ipHeaderLength + sizeof(ICMPPacket)) {
        return NULL;
    }
    
    return (ICMPPacket *)((char *)packet + ipHeaderLength);
}

// 从IPv6数据包中解析出ICMP
// https://tools.ietf.org/html/rfc2463
+ (ICMPPacket *)unpackICMPv6Packet:(char *)packet len:(int)len {
    return (ICMPPacket *)packet;
}

+ (NSString *)formatIPv6Address:(struct in6_addr)ipv6Addr {
    NSString *address = nil;
    
    char dstStr[INET6_ADDRSTRLEN];
    char srcStr[INET6_ADDRSTRLEN];
    memcpy(srcStr, &ipv6Addr, sizeof(struct in6_addr));
    if(inet_ntop(AF_INET6, srcStr, dstStr, INET6_ADDRSTRLEN) != NULL){
        address = [NSString stringWithUTF8String:dstStr];
    }
    
    return address;
}

+ (NSString *)formatIPv4Address:(struct in_addr)ipv4Addr {
    NSString *address = nil;
    
    char dstStr[INET_ADDRSTRLEN];
    char srcStr[INET_ADDRSTRLEN];
    memcpy(srcStr, &ipv4Addr, sizeof(struct in_addr));
    if(inet_ntop(AF_INET, srcStr, dstStr, INET_ADDRSTRLEN) != NULL) {
        address = [NSString stringWithUTF8String:dstStr];
    }
    
    return address;
}
@end
