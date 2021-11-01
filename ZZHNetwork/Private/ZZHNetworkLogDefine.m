//
//  ZZHNetworkLogDefine.m
//  ZZHNetwork
//
//  Created by 周子和 on 2021/11/1.
//

#import "ZZHNetworkLogDefine.h"

static BOOL LogSwitch = YES;

@implementation ZZHNetworkLogDefine

void ZZHNetworkLog(NSString *FORMAT, ...) {
    if (LogSwitch) {
        va_list args;
        va_start(args, FORMAT);
        NSString *string = [[NSString alloc] initWithFormat:FORMAT arguments:args];
        va_end(args);
        NSString *strFormat = [NSString stringWithFormat:@"%@", string];
        
        fprintf(stderr,"[%s:%d行] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [strFormat UTF8String]);
    }
}

+ (BOOL)logEnable {
    return LogSwitch;
}

+ (void)setLogEnable:(BOOL)flag {
    LogSwitch = flag;
}


@end
