//
//  ZZHNetworkConcurrentRequest.m
//  ZZHNetwork
//
//  Created by 周子和 on 2023/2/1.
//

#import "ZZHNetworkConcurrentRequest.h"
#import "ZZHNetworkRequest.h"
#import "ZZHNetworkDefine.h"
#import "ZZHNetworkConcurrentAgent.h"
#import "ZZHNetworkResponse.h"
#import "ZZHNetworkConcurrentModel.h"
#import "ZZHNetworkLog.h"

@interface ZZHNetworkConcurrentRequest () <ZZHNetworkRequestDelegate>

///  网络任务正在执行
@property (nonatomic, assign, readwrite) BOOL executing;

/// 存放所有请求 request 的数组
@property (nonatomic, strong) NSMutableArray <ZZHNetworkConcurrentModel *>*modelArr;;
@property (nonatomic, assign) NSInteger finishedCount; // 请求完成数量

@property (nonatomic, copy, nullable) void (^completion)(void);

@end

@implementation ZZHNetworkConcurrentRequest

- (void)dealloc {
    [ZZHNetworkLog logConcurrentRequestMes:@"并发请求销毁啦"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modelArr = [NSMutableArray array];
        _finishedCount = 0;
    }
    return self;
}

#pragma mark -  Public Method

- (void)addRequest:(ZZHNetworkRequest *)request
    successHandler:(nullable ZZHNetworkSuccessHandler)successHandler
    failureHandler:(nullable ZZHNetworkFailHandler)failureHandler {
    request.delegate = self;
    
    ZZHNetworkConcurrentModel *model = [[ZZHNetworkConcurrentModel alloc] init];
    model.request = request;
    model.success = successHandler;
    model.failure = failureHandler;
    
    [self.modelArr addObject:model];
}

- (void)startOnCompletion:(void (^)(void))completion {
    self.completion = completion;
    
    [self start];
}

- (void)cancel {
    for (ZZHNetworkConcurrentModel *model in self.modelArr) {
        [model.request cancel];
    }
    
    [[ZZHNetworkConcurrentAgent sharedAgent] removeConcurrentRequest:self];
}

#pragma mark - Private Method

- (void)start {
    if (_executing) {
        [ZZHNetworkLog logConcurrentRequestMes:@"并发请求正在执行中"];
        return;
    }
    _failedRequest = nil;
    _executing = YES;
    [[ZZHNetworkConcurrentAgent sharedAgent] addConcurrentRequest:self];
    for (ZZHNetworkConcurrentModel *model in self.modelArr) {
        [model.request start];
    }
}

// 重置设置
- (void)resetAction {
    self.completion = nil;
    _executing = NO;
    _finishedCount = 0;
    [[ZZHNetworkConcurrentAgent sharedAgent] removeConcurrentRequest:self];
}

#pragma mark - ZZHNetworkRequestDelegate

- (void)request:(ZZHNetworkRequest *)request didCallCallBack:(ZZHNetworkResponse *)response {
    _finishedCount++;
    [ZZHNetworkLog logConcurrentRequestMes:@"并发请求完成数量: %ld", _finishedCount];
    
    ZZHNetworkConcurrentModel *currentModel;
    for (ZZHNetworkConcurrentModel *model in self.modelArr) {
        if ([model.request isEqual:request]) {
            currentModel = model;
        }
    }
    
    if (response.type == ZZHNetworkResponseTypeSuccess) {
        if (currentModel.success) {
            currentModel.success(response.responseObject);
        }
    } else if (response.type == ZZHNetworkResponseTypeFailure)  {
        if (currentModel.failure) {
            currentModel.failure(response.error);
        }
    } else {
        //取消. 啥都不做
    }
    
    // 如果所有的请求都完成了, 则调用并发请求的回调, 然后重置设置
    if (_finishedCount == self.modelArr.count) {
        [ZZHNetworkLog logConcurrentRequestMes:@"并发请求全部完成"];
        self.executing = NO;
        
        if (self.completion) {
            self.completion();
        }
        
        [self resetAction];
    }
}

@end
