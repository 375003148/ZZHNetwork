//
//  ZZHGetRequest.m
//  ZZHNetwork_Example
//
//  Created by 周子和 on 2020/5/26.
//  Copyright © 2020 375003148. All rights reserved.
//

#import "ZZHGetRequest.h"

@implementation ZZHGetRequest

#pragma mark - Override

//请求类型
- (ZZHNetworkRequestType)requestType {
    return ZZHNetworkRequestTypeGet;
}
//请求完整的URL
- (NSString *)requestURLString {
    return @"https://www.baidu.com";
}

- (ZZHNetworkRequestSerializerType)requestSerializerType {
    return ZZHNetworkRequestSerializerTypeHTTP;
}

- (ZZHNetworkResponseSerializerType)responseSerializerType {
    return ZZHNetworkResponseSerializerTypeHTTP;
}

@end
