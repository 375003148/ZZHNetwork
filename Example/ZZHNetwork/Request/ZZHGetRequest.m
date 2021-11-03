//
//  ZZHGetRequest.m
//  ZZHNetwork_Example
//
//  Created by 周子和 on 2020/5/26.
//  Copyright © 2020 375003148. All rights reserved.
//

#import "ZZHGetRequest.h"

@implementation ZZHGetRequest {
    NSString *_username;
    NSString *_password;
}

- (id)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        _username = username;
        _password = password;
    }
    return self;
}

#pragma mark - Override

//请求类型
- (ZZHNetworkRequestType)requestType {
    return ZZHNetworkRequestTypeGet;
}

- (NSString *)baseURLString {
    return @"https://www.baidu.com";
}

//请求完整的URL
- (NSString *)requestURLString {
    return @"/1";
}

- (NSDictionary *)requestParameters{
    return @{
        @"username": _username,
        @"password": _password
    };
}

//- (ZZHNetworkRequestSerializerType)requestSerializerType {
//    return ZZHNetworkRequestSerializerTypeHTTP;
//}
//
//- (ZZHNetworkResponseSerializerType)responseSerializerType {
//    return ZZHNetworkResponseSerializerTypeHTTP;
//}

@end
