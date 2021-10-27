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

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allowsCellularAccess = YES;
    }
    return self;
}

#pragma mark - Public Method

- (void)start {
    [self startOnProgress:nil onSuccess:nil onFailure:nil onCancel:nil];
}

- (void)startOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
             onFailure:(nullable ZZHNetworkFailHandler)failHandler {
    [self startOnProgress:nil onSuccess:successHandler onFailure:failHandler onCancel:nil];
}

- (void)startOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
             onFailure:(nullable ZZHNetworkFailHandler)failHandler
              onCancel:(nullable ZZHNetworkCancelHandler)cancelHandler {
    [self startOnProgress:nil onSuccess:successHandler onFailure:failHandler onCancel:cancelHandler];
}

- (void)startOnProgress:(nullable ZZHNetworkProgress)progress
              onSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
              onFailure:(nullable ZZHNetworkFailHandler)failHandler
               onCancel:(nullable ZZHNetworkCancelHandler)cancelHandler {
    // 根据不同的情况执行不同的操作
    if (!self.isExecuting) {
        // 没有正在执行的请求, 直接开始
    } else if (self.requestStrategy == ZZHRequestStrategyByOld) {
        // 啥都不做
        return;
    } else {
        // 取消旧请求,开始新的
        [self cancel];
    }
    
    [[ZZHNetworkAgent sharedAgent] startRequest:self];
}

- (void)cancel {
    [[ZZHNetworkAgent sharedAgent] cancelRequest:self];;
}

- (BOOL)isExecuting {
    return self.sessionTask != nil;
}

@end

