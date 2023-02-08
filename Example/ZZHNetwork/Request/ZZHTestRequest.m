//
//  ZZHTestRequest.m
//  ZZHNetwork_Example
//
//  Created by 周子和 on 2023/2/1.
//  Copyright © 2023 375003148. All rights reserved.
//

#import "ZZHTestRequest.h"

@implementation ZZHTestRequest

- (ZZHNetworkLogLevel)logLevel {
    return ZZHNetworkLogLevelOff;
}

//请求类型
- (ZZHNetworkRequestType)requestType {
    return ZZHNetworkRequestTypeGet;
}

- (NSString *)baseURLString {
    return @"https://www.baidu.com";
}

//请求完整的URL
- (NSString *)requestURLString {
    return @"1";
}

@end
