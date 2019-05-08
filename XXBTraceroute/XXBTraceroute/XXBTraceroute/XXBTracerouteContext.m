//
//  XXBTracerouteContext.m
//  XXBTraceroute
//
//  Created by xiaobing5 on 2019/5/7.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "XXBTracerouteContext.h"

@implementation XXBTracerouteContext

+ (instancetype)defaultContext {
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        [self initDefaultData];
    }
    return self;
}

- (void)initDefaultData {
    
    self.maxTtl = XXBTracerouteContextMaxTtl_DEF;
    self.stepMaxAttempts = XXBTracerouteContextStepMaxAttempts_DEF;
    self.stepTimeout = XXBTracerouteContextStepTimeout_DEF;
}
@end
