//
//  ZZHNetworkRequest.m
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/9.
//  Copyright © 2020 周子和. All rights reserved.
//

#import "ZZHNetworkRequest.h"
#import "ZZHNetworkAgent.h"
#import "AFNetworking.h"

@interface ZZHNetworkRequest ()

@end

@implementation ZZHNetworkRequest

#pragma mark - Public Method

- (void)start {
    [[ZZHNetworkAgent sharedAgent] resumeRequest:self];
}

- (void)startWithCompleteHandlerOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler failHandler:(nullable ZZHNetworkFailHandler)failHandler {
    self.successHandler = successHandler;
    self.failHandler = failHandler;
    
    [self start];
}

- (void)cancel {
    [[ZZHNetworkAgent sharedAgent] cancelRequest:self];;
}

#pragma mark - Private Method

- (BOOL)isExecuting {
    NSURLSessionTask *sessionTask = self.sessionTask;
    if (sessionTask) {
        return sessionTask.state == NSURLSessionTaskStateRunning;
    } else {
        return NO;
    }
}

#pragma mark - Subclass Override

- (ZZHNetworkRequestType)requestType {
    return ZZHNetworkRequestTypePost;
}

- (nullable NSString *)requestURLString {
    return nil;
}

- (nullable NSDictionary *)requestParameters {
    return nil;
}

- (NSTimeInterval)requestTimeoutInterval {
    return 15;
}

- (BOOL)allowsCellularAccess {
    return YES;;
}

- (ZZHNetworkRequestSerializerType)requestSerializerType {
    return ZZHNetworkRequestSerializerTypeHTTP;
}

- (ZZHNetworkResponseSerializerType)responseSerializerType {
    return ZZHNetworkResponseSerializerTypeJSON;
}

@end

