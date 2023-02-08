//
//  ZZHNetworkConcurrentRequest.h
//  ZZHNetwork
//
//  Created by 周子和 on 2023/2/1.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkDefine.h"
#import "ZZHNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

/// 多个网络请求并发.
@interface ZZHNetworkConcurrentRequest : NSObject

///  网络任务正在执行
@property (nonatomic, assign, readonly) BOOL executing;

///  The first request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) ZZHNetworkRequest *failedRequest;


- (void)addRequest:(ZZHNetworkRequest *)request
    successHandler:(nullable ZZHNetworkSuccessHandler)successHandler
    failureHandler:(nullable ZZHNetworkFailHandler)failureHandler;


/// 并发请求全部完成 (添加的所有请求均成功,失败或者取消了) .  
/// - Parameter completion: 完成的回调block
- (void)startOnCompletion:(void (^)(void))completion;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
