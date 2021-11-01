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
/// 网络请求成功的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkSuccessHandler successHandler;
/// 网络请求失败的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkFailHandler failHandler;
/// 网络请求取消的block.  取消的时候马上在主线程执行
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkCancelHandler cancelHandler;


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
    
    
    //开启一个网络请求
    self.progressBlock = progress;
    self.successHandler = successHandler;
    self.failHandler = failHandler;
    self.cancelHandler = cancelHandler;
    [[ZZHNetworkAgent sharedAgent] startRequest:self];
}

- (void)cancel {
    [[ZZHNetworkAgent sharedAgent] cancelRequest:self];;
}

- (BOOL)isExecuting {
    return self.sessionTask != nil;
}

// 删除所有回调 block
- (void)clearAllBlocks {
    self.progressBlock = nil;
    self.successHandler = nil;
    self.failHandler = nil;
    self.cancelHandler = nil;
}

@end

