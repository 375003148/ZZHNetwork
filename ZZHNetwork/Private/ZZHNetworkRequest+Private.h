//
//  ZZHNetworkRequest+Private.h
//  ZZHNetwork
//
//  Created by 周子和 on 2021/11/1.
//

#import <ZZHNetwork/ZZHNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZHNetworkRequest (Private)

/// 记录当前sessionTask, 如果为nil则表示没有正在执行的网络请求
@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;

@end

NS_ASSUME_NONNULL_END
