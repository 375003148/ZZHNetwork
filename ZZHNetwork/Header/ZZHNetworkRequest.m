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
#import "ZZHNetworkLog.h"

@interface ZZHNetworkRequest ()

@property (nonatomic, strong, nullable, readwrite) NSMutableArray <id<ZZHNetworkInterceptor>> *requestInterceptors;

@property (nonatomic, copy, nullable, readwrite) ZZHNetworkProgress progressBlock;
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkVoidHandler beforeCallBackHandler;
@property (nonatomic, copy, nullable, readwrite) ZZHNetworkSuccessHandler successHandler;
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
    [self startOnProgress:nil beforeCompletion:nil onSuccess:nil onFailure:nil];
}

- (void)startOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
             onFailure:(nullable ZZHNetworkFailHandler)failHandler {
    [self startOnProgress:nil beforeCompletion:nil onSuccess:successHandler onFailure:failHandler];
}

- (void)startBeforeCompletion:(nullable ZZHNetworkVoidHandler)beforeCompletion
                    onSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
                    onFailure:(nullable ZZHNetworkFailHandler)failHandler {
    [self startOnProgress:nil beforeCompletion:beforeCompletion onSuccess:successHandler onFailure:failHandler];
}

- (void)startOnProgress:(nullable ZZHNetworkProgress)progress
       beforeCompletion:(nullable ZZHNetworkVoidHandler)beforeCompletion
              onSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
              onFailure:(nullable ZZHNetworkFailHandler)failHandler {
    // 根据不同的情况执行不同的操作
    if (!self.isExecuting) {
        // 没有正在执行的请求, 直接开始
    } else if (self.requestStrategy == ZZHRequestStrategyByOld) {
        // 旧请求正在执行中, 新请求直接忽略掉
        [ZZHNetworkLog logRequest:self mes:@"重复请求, 继续执行旧请求"];
        
        return;
    } else {
        // 取消旧请求,开始新请求
        [ZZHNetworkLog logRequest:self mes:@"重复请求, 取消旧请求, 执行新请求"];

        [self cancel];
    }
    
    //开启一个网络请求
    self.progressBlock = progress;
    self.beforeCallBackHandler = beforeCompletion;
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
    self.beforeCallBackHandler = nil;
    self.successHandler = nil;
    self.failHandler = nil;
}

- (void)addInterceptor:(id<ZZHNetworkInterceptor>)interceptor {
    if (!self.requestInterceptors) {
        self.requestInterceptors = [NSMutableArray array];
    }
    [self.requestInterceptors addObject:interceptor];
}

- (void)removeInterceptor:(id<ZZHNetworkInterceptor>)interceptor {
    if (!self.requestInterceptors) {
        self.requestInterceptors = [NSMutableArray array];
    }
    [self.requestInterceptors removeObject:interceptor];
}

- (NSArray <id<ZZHNetworkInterceptor>> *)allRequestInterceptors {
    return [self.requestInterceptors copy];;
}

@end

