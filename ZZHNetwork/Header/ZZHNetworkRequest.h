//
//  ZZHNetworkRequest.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/9.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkDefine.h"
#import "ZZHNetworkResponse.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * ZZHNetworkRequest对象绑定唯一的网络请求, 可以随时修改ZZHNetworkRequest属性不会对原有的网络请求配置和回调产生影响.
 * 请在主线程使用这个类.
 */
@interface ZZHNetworkRequest : NSObject

#pragma mark - 可读信息

///  网络任务正在执行
@property (nonatomic, readonly) BOOL isExecuting;
/// 网络请求进度. 注意: 这个回调不是在主线程, 且 GET 和 POST 才有效.
@property (nonatomic, copy, nullable, readonly) ZZHNetworkProgress progressBlock;
/// 网络回调完成的 block.   在 main queue 执行. (在任何情况下都会触发调用)
@property (nonatomic, copy, nullable, readonly) ZZHNetworkVoidHandler beforeCallBackHandler;
/// 网络请求成功的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable, readonly) ZZHNetworkSuccessHandler successHandler;
/// 网络请求失败的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable, readonly) ZZHNetworkFailHandler failHandler;


#pragma mark - 网络设置(子类继承进行设置)

/// 网络请求策略.  默认是 ZZHRequestStrategyByOld, 多次调用时已初始的请求为准
@property (nonatomic, assign) ZZHRequestStrategy requestStrategy;

/// 网络请求回调代理.
@property (nonatomic, weak, nullable) id <ZZHNetworkRequestDelegate> delegate;

/// 请求类型.  默认 ZZHNetworkRequestTypePost
@property (nonatomic, assign) ZZHNetworkRequestType requestType;

/// 请求 URL  (例如：/detail/list , 如果是完整的 URL 则不会拼接 baseURLString)
@property (nonatomic, copy, nullable) NSString *requestURLString;

/// 请求参数
@property (nonatomic, copy, nullable) id requestParameters;

/// 请求优先级, 默认 ZZHRequestPriorityDefault
@property (nonatomic, assign) ZZHRequestPriority requestPriority;

/// 在POST中构建 HTTP Body 的block.   注意: constructingBlock存在时参数必须为NSDictionary
@property (nonatomic, copy, nullable) ZZHConstructingBlock constructingBlock;

/// 同时设置了 resumableDownloadPath(注意不为nil) + GET请求, 则表示是断点下载
@property (nonatomic, copy, nullable) NSString *resumableDownloadPath;

// ======== 一般用于service统一配置 ========

/// 请求 BaseURL  (例如：http://186.134.321.34)
@property (nonatomic, copy, nullable) NSString *baseURLString;

/// 预处理器
@property (nonatomic, strong, nullable) id<ZZHNetworkPreproccess>preprocessor;

/// 超时时间. 0表示不设置超时
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

/// 允许使用蜂窝网络. 默认YES
@property (nonatomic, assign) BOOL allowsCellularAccess;

/// 请求序列类型, 默认 ZZHNetworkRequestSerializerTypeHTTP
@property (nonatomic, assign) ZZHNetworkRequestSerializerType requestSerializerType;

/// 响应序列类型, 默认 ZZHNetworkResponseSerializerTypeHTTP
@property (nonatomic, assign) ZZHNetworkResponseSerializerType responseSerializerType;

///  Username and password used for HTTP authorization. Should be formed as @[@"Username", @"Password"].
@property (nonatomic, copy) NSArray<NSString *> *requestAuthorizationHeaderFieldArray;

/// 增添请求头参数
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *requestHeaderFieldValueDictionary;

/// 打印等级. 默认 ZZHNetworkLogLevelDefault
@property (nonatomic, assign) ZZHNetworkLogLevel logLevel;

#pragma mark - public Action

- (void)start;

- (void)startOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
             onFailure:(nullable ZZHNetworkFailHandler)failHandler;

- (void)startBeforeCompletion:(nullable ZZHNetworkVoidHandler)beforeCompletion
                    onSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
                    onFailure:(nullable ZZHNetworkFailHandler)failHandler;

/// 开始网络请求
/// @param progress 进度回调
/// @param beforeCompletion 完成之前的回调. 会优先于任何回调且必执行的.  一般用来处理一些公共事务, 如 hud 的消失.
/// @param successHandler 成功回调. 注意被拦截或请求取消时不会执行.
/// @param failHandler 失败回调.  注意被拦截或请求取消时不会执行.
- (void)startOnProgress:(nullable ZZHNetworkProgress)progress
       beforeCompletion:(nullable ZZHNetworkVoidHandler)beforeCompletion
              onSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
              onFailure:(nullable ZZHNetworkFailHandler)failHandler;

/// 取消网络请求
/// @discussion 取消会马上执行取消回调, 并不在成功或失败的回调范围.
- (void)cancel;

/// 取消所有请求
+ (void)cancelAllRequests;

/// 删除所有回调. 此方法供内部使用,外部不要调用
- (void)clearAllBlocks;

/// 添加拦截器
- (void)addInterceptor:(id<ZZHNetworkInterceptor>)interceptor;

/// 删除拦截器
- (void)removeInterceptor:(id<ZZHNetworkInterceptor>)interceptor;

/// 获取所有的拦截器
- (NSArray <id<ZZHNetworkInterceptor>> *)allRequestInterceptors;

@end

NS_ASSUME_NONNULL_END
