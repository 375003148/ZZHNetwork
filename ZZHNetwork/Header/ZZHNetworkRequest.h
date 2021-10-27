//
//  ZZHNetworkRequest.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/9.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkDefine.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * ZZHNetworkRequest对象绑定唯一的网络请求, 可以随时修改ZZHNetworkRequest属性不会对原有的网络请求配置和回调产生影响.
 * 请在主线程使用这个类.
 */
@interface ZZHNetworkRequest : NSObject

#pragma mark - 

///  网络任务正在执行
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;

#pragma mark - 网络设置(子类继承进行设置)

/// 网络请求策略.  默认是 ZZHRequestStrategyByOld,多次调用时已初始的请求为准
@property (nonatomic, assign) ZZHRequestStrategy requestStrategy;

/// 网络请求回调代理.
@property (nonatomic, weak, nullable) id <ZZHNetworkRequestDeledate> delegate;

/// 请求类型.  默认 ZZHNetworkRequestTypePost
@property (nonatomic, assign) ZZHNetworkRequestType requestType;

/// 请求完整的URL  (例如：/detail/list)
@property (nonatomic, copy, nullable) NSString *requestURLString;

/// 请求参数
@property (nonatomic, copy, nullable) NSDictionary *requestParameters;



/// 请求优先级, 默认 ZZHRequestPriorityDefault
@property (nonatomic, assign) ZZHRequestPriority requestPriority;

/// 在POST中构建 HTTP Body 的block
@property (nonatomic, copy, nullable) ZZHConstructingBlock constructingBlock;

/// 同时设置了 resumableDownloadPath(注意不为nil) + GET请求, 则表示是断点下载
@property (nonatomic, copy, nullable) NSString *resumableDownloadPath;

// ======== 一般用于service统一配置 ========

/// 预处理参数
@property (nonatomic, copy, nullable) ZZHNetworkPreproccessParameter parameterPreprocess;

/// 预处理成功数据
@property (nonatomic, copy, nullable) ZZHNetworkPreproccessSuccess successPreprocess;

/// 拦截器
@property (nonatomic, strong, nullable) id<ZZHNetworkInterceptor> requestInterceptor;

/// 超时时间. 0表示不设置超时
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

/// 允许使用蜂窝网络, 默认YES
@property (nonatomic, assign) BOOL allowsCellularAccess;

/// 请求序列类型, 默认 ZZHNetworkRequestSerializerTypeHTTP
@property (nonatomic, assign) ZZHNetworkRequestSerializerType requestSerializerType;

/// 响应序列类型, 默认 ZZHNetworkResponseSerializerTypeHTTP
@property (nonatomic, assign) ZZHNetworkResponseSerializerType responseSerializerType;

///  Username and password used for HTTP authorization. Should be formed as @[@"Username", @"Password"].
@property (nonatomic, copy) NSArray<NSString *> *requestAuthorizationHeaderFieldArray;

/// 增添请求头参数
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *requestHeaderFieldValueDictionary;



#pragma mark - public Action
/// 开始网络请求.
/// @discussion 可以配合 delegate 一起使用
- (void)start;

/// 开始网络请求
/// @param successHandler 请求成功的回调
/// @param failHandler 请求失败的回调
/// @discussion 这个方法使用 block 进行回调, 切记不要同时和 delegate 使用
- (void)startOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
             onFailure:(nullable ZZHNetworkFailHandler)failHandler;


/// 开始网络请求
/// @param successHandler 请求成功的回调
/// @param failHandler 请求失败的回调
/// @param cancelHandler 请求取消的回调, 在一些有需要的场景才会用到
- (void)startOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler
             onFailure:(nullable ZZHNetworkFailHandler)failHandler
              onCancel:(nullable ZZHNetworkCancelHandler)cancelHandler;

///  取消网络请求
/// @discussion 取消会马上执行取消回调, 并不在成功或失败的回调范围.
- (void)cancel;

@end


/// 内部使用的属性, 外部不要操作
@interface ZZHNetworkRequest ()

#pragma mark - 网络回调
/// 网络请求成功的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable) ZZHNetworkSuccessHandler successHandler;
/// 网络请求失败的回调block.   在 main queue 执行
@property (nonatomic, copy, nullable) ZZHNetworkFailHandler failHandler;
/// 网络请求取消的block.  取消的时候马上在主线程执行
@property (nonatomic, copy, nullable) ZZHNetworkCancelHandler cancelHandler;
/// 网络请求进度. 注意: 这个回调不是在主线程, 且 GET 和 POST 才有效.
@property (nonatomic, copy, nullable) ZZHNetworkProgress progressBlock;

#pragma mark - ZZHNetworkAgent 内部使用, 别的类里面只可以读取
/// 记录当前sessionTask, 如果为nil则表示没有正在执行的网络请求
@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;

@end

NS_ASSUME_NONNULL_END
