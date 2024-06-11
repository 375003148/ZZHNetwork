//
//  ZZHNetworkLog.h
//  ZZHNetwork
//
//  Created by 周子和 on 2023/1/3.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

/// 按照 request 打印等级进行各部分数据的打印
@interface ZZHNetworkLog : NSObject

// 打印网络请求开始(包括URL,请求参数)
+ (void)logRequestStart:(ZZHNetworkRequest *)request;

/// 打印网络请求原始返回数据
+ (void)logRequestResponse:(nonnull ZZHNetworkRequest *)request
            responseObject:(nullable id)responseObject
                     error:(nullable NSError *)error;

/// 打印网络请求成功的最终数据
+ (void)logSuccess:(nonnull ZZHNetworkRequest *)request responseObject:(nullable id)responseObject;
/// 打印网络请求失败的最终数据
+ (void)logFailure:(nonnull ZZHNetworkRequest *)request error:(nullable NSError *)error;

///  打印信息
+ (void)logRequest:(nonnull ZZHNetworkRequest *)request mes:(NSString *)mes, ...;


///  并发请求打印
+ (void)logConcurrentRequestMes:(NSString *)mes, ...;

@end

NS_ASSUME_NONNULL_END
