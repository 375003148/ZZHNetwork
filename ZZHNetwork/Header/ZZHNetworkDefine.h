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
    ZZHRequestStrategyByNew,     // 多次调用时只执行最新的请求
    
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
typedef void (^ZZHNetworkCancelHandler)(void);
typedef void (^ZZHNetworkProgress)(NSProgress * _Nullable progress);

/// 构建上传数据的block
@protocol AFMultipartFormData;
typedef void(^ZZHConstructingBlock)(id<AFMultipartFormData> _Nonnull formData);

/// 预处理请求参数
typedef NSDictionary *_Nullable(^ZZHNetworkPreproccessParameter)(NSDictionary *_Nullable parameter);
/// 预处理成功返回结果.  block 返回 nil 表示结果上报到上层进行处理, 此时不走成功的 block 和代理回调 和 拦截器的 requestAfterCallBack 方法
typedef id _Nullable(^ZZHNetworkPreproccessSuccess)(id _Nullable responseObject);

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
#ifndef zzh_dispatch_main_async_safe
#define zzh_dispatch_main_async_safe(block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif


/// __weak的宏定义.  使用时  @ZZHWeakify(self) 即可使用 weak_self 了
#ifndef ZZHWeakify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define ZZHWeakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
            #define ZZHWeakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
            #define ZZHWeakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
            #define ZZHWeakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif


/// __strong的宏定义
#ifndef ZZHStrongify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define ZZHStrongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
            #define ZZHStrongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
            #define ZZHStrongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
            #define ZZHStrongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif
