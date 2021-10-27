//
//  ZZHNetworkAgent.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/6.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZHNetworkAgent : NSObject

/// 单例创建
+ (instancetype)sharedAgent;

/// 开始网络请求
- (void)startRequest:(nonnull ZZHNetworkRequest *)request;

/// 取消网络请求
- (void)cancelRequest:(nullable ZZHNetworkRequest *)request;

/// 取消所有网络请求
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
