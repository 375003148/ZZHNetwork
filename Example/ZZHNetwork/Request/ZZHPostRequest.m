//
//  ZZHPostRequest.m
//  ZZHNetwork_Example
//
//  Created by 周子和 on 2024/6/11.
//  Copyright © 2024 375003148. All rights reserved.
//

#import "ZZHPostRequest.h"

@implementation ZZHPostRequest

- (NSString *)requestURLString {
    return @"https://139.196.59.100:9443/imgCaptcha/create";
}

- (ZZHNetworkRequestType)requestType {
    return ZZHNetworkRequestTypePost;
}

- (id)requestParameters {
    return @{
        @"request": @{
            @"captchaType": @"LOGIN",
            @"terminalCode": [self createRandomNumber],
        }
    };
}

// 生成4位随机数
- (NSString *)createRandomNumber {
    int num = (arc4random() % 10000);
    NSString *randomNumber = [NSString stringWithFormat:@"%.4d", num];
    return randomNumber;
}

@end
