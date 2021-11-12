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
#import "ZZHNetworkRequest+Private.h"

@interface ZZHNetworkRequest ()

/// 网络请求进度. 注意: 这个回调不是在主线程, 且 GET 和 POST 才有效.
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkProgress progressBlock;
/// 网络回调完成的 block.   在 main queue 执行. (比成功和失败的 block 先调用)
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkVoidHandler completionHandler;
/// 网络请求成功的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkSuccessHandler successHandler;
/// 网络请求失败的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkFailHandler failHandler;


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
    [self startOnProgress:nil onCompletion:nil onSuccess:nil onFailure:nil];
}

- (void)startOnCompletion:(nullable ZZHNetworkVoidHandler)complitionHandler
        onSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
              onFailure:(nullable ZZHNetworkFailHandler)failHandler {
    [self startOnProgress:nil onCompletion:complitionHandler onSuccess:successHandler onFailure:failHandler];
}

- (void)startOnProgress:(nullable ZZHNetworkProgress)progress
           onCompletion:(nullable ZZHNetworkVoidHandler)complitionHandler
              onSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
              onFailure:(nullable ZZHNetworkFailHandler)failHandler {
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
    
    
    //开启一个网络请求
    self.progressBlock = progress;
    self.completionHandler = complitionHandler;
    self.successHandler = successHandler;
    self.failHandler = failHandler;
    [[ZZHNetworkAgent sharedAgent] startRequest:self];
}

- (void)cancel {
    [[ZZHNetworkAgent sharedAgent] cancelRequest:self];;
}

+ (void)cancelAllRequests {
    [[ZZHNetworkAgent sharedAgent] cancelAllRequests];;
}

- (BOOL)isExecuting {
    return self.sessionTask != nil;
}

// 删除所有回调 block
- (void)clearAllBlocks {
    self.progressBlock = nil;
    self.completionHandler = nil;
    self.successHandler = nil;
    self.failHandler = nil;
}

@end

