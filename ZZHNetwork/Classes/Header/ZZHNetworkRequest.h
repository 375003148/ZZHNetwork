//
//  ZZHNetworkRequest.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/9.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkDefine.h"

@protocol AFMultipartFormData;
typedef void(^ZZHConstructingBlock)(id<AFMultipartFormData> _Nonnull formData);

NS_ASSUME_NONNULL_BEGIN
/**
 * 使用时继承这个类,复写override方法进行配置.
 * 每一个request对象都只对应一个单独的请求
 * 请在主线程使用这个类
 */
@interface ZZHNetworkRequest : NSObject

///  网络任务正在执行
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;


#pragma mark - Request Configuration

/// 网络请求回调代理. 代理与block不同之处在于设置了之后是永久的, 需要使用者自己去掌握
@property (nonatomic, weak) id <ZZHNeteorkRequestCallBackDeledate> delegate;

/// 在POST中构建 HTTP Body 的block, 默认为nil
@property (nonatomic, copy, nullable) ZZHConstructingBlock constructingBlock;

/// 同时设置了 resumableDownloadPath(注意不为nil) + GET请求, 则表示是断点下载
@property (nonatomic, copy, nullable) NSString *resumableDownloadPath;

/// 网络请求进度. 只有 GET 和 POST 才能使用. 注意这个回调不是在主线程. 并且只在 request start 之前设置才有效, 不要多次设置
@property (nonatomic, copy, nullable) ZZHNetworkProgress progressBlock;


#pragma mark - Request Action

/// 开始网络请求任务.
/// @discussion 此方法做了防止重复调用处理. 如果有有正在执行的网络任务, 则不做任何操作, 如果没有正在执行的网络任务则创建一个并resume.
- (void)start;

/// 设置了成功和失败的回调block并调用start.
/// @discussion 注意不管在哪设置的成功和失败的回调block, 他们在请求成功、失败或被取消时都会被置为nil.
- (void)startWithCompleteHandlerOnSuccess:(nullable ZZHNetworkSuccessHandler)successHandler failHandler:(nullable ZZHNetworkFailHandler)failHandler;

///  取消网络请求
/// @discussion 请求被取消时不会触发block和delegate回调, 并会将成功和失败的回调block置为nil.
- (void)cancel;


#pragma mark - Subclass Override

/// 请求类型, 默认post
- (ZZHNetworkRequestType)requestType;

/// 请求完整的URL, 默认nil
- (nullable NSString *)requestURLString;

/// 请求参数, 默认nil
- (nullable NSDictionary *)requestParameters;

/// 超时时间, 默认15s
- (NSTimeInterval)requestTimeoutInterval;

/// 是否允许使用蜂窝网络, 默认YES
- (BOOL)allowsCellularAccess;

/// 请求序列类型, 默认 ZZHNetworkRequestSerializerTypeHTTP
- (ZZHNetworkRequestSerializerType)requestSerializerType;

/// 响应序列类型, 默认 ZZHNetworkResponseSerializerTypeJSON
- (ZZHNetworkResponseSerializerType)responseSerializerType;


#pragma mark - SDK私有的一些属性, 外面不要使用

/// 创建完sessionTask时马上存储在这里以供后面使用
@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;
/// 根据对应格式处理后的 responseObject, 下载任务成功时这里存放的是文件存放URL
@property (nonatomic, strong, nullable) id responseObject;
/// responseObject二进制数据
@property (nonatomic, strong, nullable) NSData *responseData;
/// responseObject二进制数据的字符串
@property (nonatomic, strong, nullable) NSString *responseString;
/// error
@property (nonatomic, strong, nullable) NSError *error;

/// 网络请求成功的回调block
@property (nonatomic, copy, nullable) ZZHNetworkSuccessHandler successHandler;

/// 网络请求失败的回调block
@property (nonatomic, copy, nullable) ZZHNetworkFailHandler failHandler;

@end

NS_ASSUME_NONNULL_END
