//
//  ZZHNetworkAgent.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/6.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkDefine.h"

@class ZZHNetworkRequest;

NS_ASSUME_NONNULL_BEGIN

@interface ZZHNetworkAgent : NSObject

/// 单例创建
+ (instancetype)sharedAgent;

/// 开始网络请求
/// @discussion 如果有request中有正在执行的sessionTask, 则不做任何操作, 否则创建一个新的sessionTask并resume.
- (void)resumeRequest:(nonnull ZZHNetworkRequest *)request;

/// 取消网络请求
/// @discussion 取消网络请求时不会走成功和失败的回调block, 并且会清除掉这些block
- (void)cancelRequest:(nonnull ZZHNetworkRequest *)request;

@end

NS_ASSUME_NONNULL_END
