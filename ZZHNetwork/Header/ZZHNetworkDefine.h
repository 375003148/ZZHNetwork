//
//  ZZHNetworkDefine.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/6.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 请求优先级
typedef NS_ENUM(NSInteger, ZZHRequestStrategy) {
    ZZHRequestStrategyByOld = 0, // 多次调用时只执行初始的请求 
    ZZHRequestStrategyByNew,     // 多次调用时只执行最新的请求 (旧的会被cancel掉)
};

/// 请求优先级
typedef NS_ENUM(NSInteger, ZZHRequestPriority) {
    ZZHRequestPriorityLow = -4L,
    ZZHRequestPriorityDefault = 0,
    ZZHRequestPriorityHigh = 4,
};

/// 请求方式
typedef NS_ENUM(NSUInteger, ZZHNetworkRequestType) {
    ZZHNetworkRequestTypePost = 0,
    ZZHNetworkRequestTypeGet,
    ZZHNetworkRequestTypeHEAD,
    ZZHNetworkRequestTypePUT,
    ZZHNetworkRequestTypeDELETE,
    ZZHNetworkRequestTypePATCH,
};

/// 请求数据格式
typedef NS_ENUM(NSUInteger, ZZHNetworkRequestSerializerType) {
    ZZHNetworkRequestSerializerTypeHTTP = 0,
    ZZHNetworkRequestSerializerTypeJSON,
};

/// 返回数据格式
typedef NS_ENUM(NSUInteger, ZZHNetworkResponseSerializerType) {
    /// NSData
    ZZHNetworkResponseSerializerTypeHTTP = 0,
    /// JSON
    ZZHNetworkResponseSerializerTypeJSON,
    /// XMLParser
    ZZHNetworkResponseSerializerTypeXMLParser
};

/// 请求的回调block
typedef void (^ZZHNetworkSuccessHandler)(id _Nullable responseObject);
typedef void (^ZZHNetworkFailHandler)(NSError * _Nullable error);
typedef void (^ZZHNetworkVoidHandler)(void);
typedef void (^ZZHNetworkProgress)(NSProgress * _Nullable progress);

/// 构建上传数据的block
@protocol AFMultipartFormData;
typedef void(^ZZHConstructingBlock)(id<AFMultipartFormData> _Nonnull formData);

#pragma mark - 网络请求回调代理

@protocol ZZHNetworkRequestDeledate <NSObject>

@optional

/// 网络请求成功的回调
- (void)requestDidSucceed:(nullable id)responseObject;

/// 网络请求失败的回调
- (void)requestDidFailed:(nullable NSError *)error;

/// 网络请求取消的回调
- (void)requestDidCancelled;

@end

#pragma mark - 预处理代理
@protocol ZZHNetworkPreproccess <NSObject>

@optional

/// 预处理参数
/// @param parameters 原始的参数字典
- (nullable id)preproccessParameter:(nullable id)parameters;


/// 预处理请求结果 (注意此方法是在子线程)
/// @return 返回最终的数据格式. 如果返回nil, 表示事件已经分发, 不执行回调. 如果为NSError则执行失败回调, 其它情况执行成功回调
- (nullable id)preproccessResponseObject:(nullable id)responseObject error:(nullable NSError *)error;

@end

#pragma mark - 网络请求拦截代理
@protocol ZZHNetworkInterceptor <NSObject>

@optional

// 请求开始之前
- (void)requestWillStart;
/// 回调之前. 包括成功和失败和取消
- (void)requestBeforeCallBack;
/// 回调之前. 包括成功和失败和取消
- (void)requestAfterCallBack;

@end

NS_ASSUME_NONNULL_END


#pragma mark - 实用的宏定义

/// 确保在主线程执行block
#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif



