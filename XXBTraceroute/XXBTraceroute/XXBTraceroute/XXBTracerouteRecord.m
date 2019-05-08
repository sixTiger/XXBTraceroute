//
//  XXBTracerouteRecord.m
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/7.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "XXBTracerouteRecord.h"
#import "XXBTracerouteCommon.h"

@implementation XXBTracerouteRecord

- (NSString *)getMessage {
    if (isEmpty_XXBTR(self.consumerMessage)) {
        
        NSMutableString *record = [[NSMutableString alloc] initWithCapacity:20];
        [record appendFormat:@"%ld\t", (long)self.ttl];
        
        if (self.ip == nil) {
        } else {
            [record appendFormat:@"%@\t", self.ip];
        }
        
        for (id number in _recvDurations) {
            if ([number isKindOfClass:[NSNull class]]) {
                [record appendFormat:@"timeout\t"];
            } else {
                [record appendFormat:@"%.2f ms\t", [(NSNumber *)number floatValue] * 1000];
            }
        }
        return record;
    } else {
        
        return self.consumerMessage;
    }
}
@end
