//
//  ZZHNetworkAgent.m
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/6.
//  Copyright © 2020 周子和. All rights reserved.
//

#import "ZZHNetworkAgent.h"
#import "AFNetworking.h"
#import <pthread/pthread.h>
#import "ZZHNetworkUtil.h"
#import "ZZHNetworkDefine.h"
#import "ZZHNetworkRequest+Private.h"
#import "ZZHNetworkLogDefine.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

typedef enum : NSUInteger {
    ZZHNetworkResponseTypeSuccess,
    ZZHNetworkResponseTypeFailure,
    ZZHNetworkResponseTypeCancel,
} ZZHNetworkResponseType;

@interface ZZHNetworkAgent () {
    pthread_mutex_t _lock;
}

/// 存储 taskIdentifier - request 的键值对
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, ZZHNetworkRequest *> *requestRecordDic;
///
@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation ZZHNetworkAgent

#pragma mark - Life Cycle

+ (instancetype)sharedAgent {
    static dispatch_once_t onceToken;
    static ZZHNetworkAgent *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZZHNetworkAgent alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestRecordDic = [NSMutableDictionary dictionary];
        pthread_mutex_init(&_lock, NULL);

        //创建 AFHTTPSessionManager
        // 设置为 AFHTTPResponseSerializer, 所有返回的数据都是NSData格式, 然后在最后根据各个request中设置的序列号分别进行数据格式的转换, 达到每个request能够定义自己的返回格式这一目的
        _manager = [AFHTTPSessionManager manager];
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        //设置非校验证书模式
        //#warning 这里安全模式需要补充
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        [_manager.securityPolicy setValidatesDomainName:NO];
        
        //设置回调的队列, 如果不设置即为主队列
        _manager.completionQueue = dispatch_queue_create("com.ZZHNetworkAgent.completion", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}


#pragma mark - Public Method
- (void)startRequest:(nonnull ZZHNetworkRequest *)request; {
    NSParameterAssert(request != nil);
    
    ZZHNetworkLog(@"");
    ZZHNetworkLog(@"========== /网络请求开始/ ==========");
    ZZHNetworkLog(@"//网络URL// -> %@", [self _getRequestUrl:request]);
    ZZHNetworkLog(@"//网络参数// -> %@", [self _getFinalParameters:request]);
   
    // 拦截器
    if ([request.requestInterceptor respondsToSelector:@selector(requestWillStart)]) {
        [request.requestInterceptor requestWillStart];
    }
    
    // 创建一个新的请求任务
    NSError * __autoreleasing requestError = nil;
    NSURLSessionTask *sessionTask = [self taskForRequest:request error:&requestError];
    if (requestError) {
        //创建task失败
        [self handleCallBack:request responseObject:nil error:requestError responseType:ZZHNetworkResponseTypeFailure];
        return;
    }

    NSAssert(sessionTask != nil, @"requestTask should not be nil");
    
    // 设置task优先级
    if ([sessionTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case ZZHRequestPriorityHigh:
                sessionTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case ZZHRequestPriorityLow:
                sessionTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case ZZHRequestPriorityDefault:
                /*!!fall through*/
            default:
                sessionTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    
    Lock();
    _requestRecordDic[@(sessionTask.taskIdentifier)] = request;
    Unlock();
    
    //开启任务
    [sessionTask resume];
    request.sessionTask = sessionTask;
    return;
}

- (void)cancelRequest:(nullable ZZHNetworkRequest *)request {
    if (!request.sessionTask) {
        return;
    }
    
    ZZHNetworkLog(@"=========== /网络请求取消/ ===========");
    
    //取消网络任务
    if (request.resumableDownloadPath && [self resumeDataPathForDownloadPath:request.resumableDownloadPath]) {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.sessionTask;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [self resumeDataPathForDownloadPath:request.resumableDownloadPath];
            [resumeData writeToURL:localUrl atomically:YES];
        }];
    } else {
        [request.sessionTask cancel];
    }

    // 处理回调
    [self handleCallBack:request responseObject:nil error:nil responseType:ZZHNetworkResponseTypeCancel];
    // 清除 request 记录
    [self clearNetworkRequest:request];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestRecordDic allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            ZZHNetworkRequest *request = _requestRecordDic[key];
            Unlock();
            // 这句不要写在锁里, 以免造成死锁
            [self cancelRequest:request];
        }
    }
}

#pragma mark - 统一处理处理请求结果
/// 网络请求返回结果处理
/// 注意: 线程不安全, 整个类只有这个方法是子线程调用
- (void)handleNetworkResult:(nullable NSURLSessionTask *)task
             responseObject:(nullable id)responseObject
                      error:(nullable NSError *)error {
    Lock();
    ZZHNetworkRequest *request = _requestRecordDic[@(task.taskIdentifier)];
    Unlock();

    //这里很重要 !!!
    // 网络请求取消时, 不进行任何回调操作
    if (!request.sessionTask) {
        return;
    }
    
    // 将数据进行格式转换, 并存储在request中
    NSError * __autoreleasing serializationError = nil;
    if ([responseObject isKindOfClass:[NSData class]]) {
        if (request.responseSerializerType != ZZHNetworkResponseSerializerTypeHTTP) {
            //根据不同的格式进行数据格式转换
            responseObject = [[self responseSerializer:request.responseSerializerType] responseObjectForResponse:task.response data:responseObject error:&serializationError];
        } else {
            //HTTP格式时,已经默认情况下做过了转换, 此时不需要再做啥
        }
    }
    
    //最终判断失败还是成功, 然后进行各自的回调操作
    NSError *requestError = nil;
    ZZHNetworkResponseType type = ZZHNetworkResponseTypeSuccess;
    if (error) {
        requestError = error;
        type = ZZHNetworkResponseTypeFailure;
    } else if (serializationError) {
        requestError = serializationError;
        type = ZZHNetworkResponseTypeFailure;
    } else {
        type = ZZHNetworkResponseTypeSuccess;
    }

    if (type == ZZHNetworkResponseTypeFailure) {
        // 下载失败时将 resume data 存放在 resume path 下
        if (request.resumableDownloadPath) {
            NSURL *tmpDownloadPath = [self resumeDataPathForDownloadPath:request.resumableDownloadPath];
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (tmpDownloadPath && resumeData) {
                [resumeData writeToURL:tmpDownloadPath atomically:YES];
            }
        }
        //下载失败时, 将数据存在request.responseData返回给外层, 并且删除掉下载路径下的数据
        if ([responseObject isKindOfClass:[NSURL class]]) {
            NSURL *url = responseObject;
            if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            }
        }
    }

    //主线程进行回调 和 清除数据
    dispatch_main_async_safe(^{
        // 如果已经取消了, 直接return
        if (!request.sessionTask) {
            return;
        }
        // 处理回调
        [self handleCallBack:request responseObject:responseObject error:requestError responseType:type];
        // 清除存储记录
        [self clearNetworkRequest:request];
    });
}

/// 注意: 所有的block和delegate回调最终都在这个方法进行处理 (主线程)
- (void)handleCallBack:(nonnull ZZHNetworkRequest *)request
        responseObject:(nullable id)responseObject
                 error:(NSError *)error
          responseType:(ZZHNetworkResponseType)type {
    ZZHNetworkLogSpace();
    ZZHNetworkLog(@"↓↓↓↓↓↓↓↓↓↓↓↓ //网络请求原始数据// ↓↓↓↓↓↓↓↓↓↓↓↓");
    ZZHNetworkLog(@"//responseObject// -> %@", responseObject);
    ZZHNetworkLog(@"//error// -> %@", error);
    ZZHNetworkLog(@"↑↑↑↑↑↑↑↑↑↑↑↑ //网络请求原始数据// ↑↑↑↑↑↑↑↑↑↑↑↑");
    ZZHNetworkLogSpace();
    
    // 回调 - completionHandler
    if (request.completionHandler) {
        request.completionHandler();
    }
    
    // 拦截器 - requestBeforeCallBack
    if ([request.requestInterceptor respondsToSelector:@selector(requestBeforeCallBack)]) {
        [request.requestInterceptor requestBeforeCallBack];
    }
    
    // 预处理返回结果
    if ([request.preprocessor respondsToSelector:@selector(preproccessResponseObject:error:)] && type != ZZHNetworkResponseTypeCancel) {
        id result = [request.preprocessor preproccessResponseObject:responseObject error:error];
        if ([result isKindOfClass:[NSNumber class]]) {
            // 结果通知上层处理了, 直接 return
            ZZHNetworkLogSpace();
            ZZHNetworkLog(@"=========== //网络结果通知上层处理, 终止回调// ===========");
            ZZHNetworkLog(@"=========== //网络请求完成// ===========");
            ZZHNetworkLogSpace();
            return;
        }
        else if ([result isKindOfClass:[NSError class]]) {
            // 失败
            type = ZZHNetworkResponseTypeFailure;
            error = result;
        } else {
            // 成功
            type = ZZHNetworkResponseTypeSuccess;
            responseObject = result;
        }
    }
    
    switch (type) {
        case ZZHNetworkResponseTypeSuccess: {
            // 1.成功回调
            ZZHNetworkLogSpace();
            ZZHNetworkLog(@"↓↓↓↓↓↓↓↓↓↓↓↓ //成功回调// ↓↓↓↓↓↓↓↓↓↓↓↓");
            ZZHNetworkLog(@"//responseObject// -> %@", responseObject);
            ZZHNetworkLog(@"↑↑↑↑↑↑↑↑↑↑↑↑ //成功回调// ↑↑↑↑↑↑↑↑↑↑↑↑");
            ZZHNetworkLogSpace();
            
            if (request.successHandler) {
                request.successHandler(responseObject);
            }
            if (request.delegate && [request.delegate respondsToSelector:@selector(requestDidSucceed:)]) {
                [request.delegate requestDidSucceed:responseObject];
            }
        }
            break;
        case ZZHNetworkResponseTypeFailure: {
            // 2.失败
            ZZHNetworkLogSpace();
            ZZHNetworkLog(@"↓↓↓↓↓↓↓↓↓↓↓↓ //失败回调// ↓↓↓↓↓↓↓↓↓↓↓↓");
            ZZHNetworkLog(@"//error// -> %@", error);
            ZZHNetworkLog(@"↑↑↑↑↑↑↑↑↑↑↑↑ //失败回调// ↑↑↑↑↑↑↑↑↑↑↑↑");
            ZZHNetworkLogSpace();
            
            if (request.failHandler) {
                request.failHandler(error);
            }
            if (request.delegate && [request.delegate respondsToSelector:@selector(requestDidFailed:)]) {
                [request.delegate requestDidFailed:error];
            }
        }
            break;
        case ZZHNetworkResponseTypeCancel: {
            // 3.取消
            if (request.delegate && [request.delegate respondsToSelector:@selector(requestDidCancelled)]) {
                [request.delegate requestDidCancelled];
            }
        }
            break;
        default:
            break;
    }
    
    // 拦截器 - requestAfterCallBack
    if ([request.requestInterceptor respondsToSelector:@selector(requestAfterCallBack)]) {
        [request.requestInterceptor requestAfterCallBack];
    }
    
    ZZHNetworkLog(@"=========== /网络请求完成/ ===========");
    ZZHNetworkLogSpace();
}

#pragma mark - 创建网络任务 sessionTask
/// 创建网络任务入口方法
- (NSURLSessionTask *)taskForRequest:(nonnull ZZHNetworkRequest *)request
                               error:(NSError * _Nullable __autoreleasing *)error {
    if (request.requestType == ZZHNetworkRequestTypeGet && request.resumableDownloadPath) {
        /// 下载任务
        return [self downloadTaskWithRequest:request error:error];;
    } else {
        // 普通任务
        return [self dataTaskWithrequest:request error:error];
    }
}

// 普通网络任务创建
- (NSURLSessionDataTask *)dataTaskWithrequest:(ZZHNetworkRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    NSString *methodName;
    ZZHNetworkProgress downloadProgress = nil;
    ZZHNetworkProgress uploadProgress = nil;
    switch (request.requestType) {
        case ZZHNetworkRequestTypeGet: {
            methodName = @"GET";
            downloadProgress = request.progressBlock;
        }
            break;
        case ZZHNetworkRequestTypePost: {
            methodName = @"POST";
            uploadProgress = request.progressBlock;
        }
            break;
        case ZZHNetworkRequestTypeHEAD: {
            methodName = @"HEAD";
        }
            break;
        case ZZHNetworkRequestTypePUT: {
            methodName = @"PUT";
        }
            break;
        case ZZHNetworkRequestTypeDELETE: {
            methodName = @"DELETE";
        }
            break;
        case ZZHNetworkRequestTypePATCH: {
            methodName = @"PATCH";
        }
            break;
        default:
            break;
    }
    
    //构建request
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    NSMutableURLRequest *URLRequest = nil;
    NSString *finalURL = [self _getRequestUrl:request];
    id finalParameters = [self _getFinalParameters:request];
    
    if (request.constructingBlock) {
        URLRequest = [requestSerializer multipartFormRequestWithMethod:methodName URLString:finalURL parameters:(NSDictionary *)finalParameters constructingBodyWithBlock:request.constructingBlock error:error];
    } else {
        URLRequest = [requestSerializer requestWithMethod:methodName URLString:finalURL parameters:finalParameters error:error];
    }

    //构架dataTask
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:URLRequest uploadProgress:uploadProgress downloadProgress:downloadProgress completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [self handleNetworkResult:dataTask responseObject:responseObject error:error];
    }];
    return dataTask;
}

/// 下载网络任务创建
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(ZZHNetworkRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    NSString *downloadPath = request.resumableDownloadPath;
    
    NSString *finalURL = [self _getRequestUrl:request];
    id finalParameters = [self _getFinalParameters:request];
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:finalURL parameters:finalParameters error:error];

    /// 处理下载路径格式, downloadTargetPath 为最终的下载地址
    // 1.判断路径下是否是文件夹
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    //2.如果下载路径下是一个文件夹的话, 就取URL最后一个元素作为文件名称拼接在后面
    NSString *downloadTargetPath;
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }

    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So we remove the exist file before we start the download task.
    // https://github.com/AFNetworking/AFNetworking/issues/3775
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    __block NSURLSessionDownloadTask *downloadTask = nil;
    // 根据resume path的下的数据存在性和有效性, 判断下载任务是继续下载还是全新的下载任务
    NSURL *resumePath = [self resumeDataPathForDownloadPath:downloadPath];
    if (resumePath) {
        BOOL resumeDataIsExists = [[NSFileManager defaultManager] fileExistsAtPath:resumePath.path];
        NSData *resumeData = [NSData dataWithContentsOfURL:resumePath];
        BOOL resumeDataIsValid = [ZZHNetworkUtil validateResumeData:resumeData];
        BOOL shouldResume = resumeDataIsExists && resumeDataIsValid;
        
        BOOL resumeSucceeded = NO;
        // 如果是可以恢复的下载, 则尝试恢复下载, 如果恢复失败则重新开启一个全新的下载任务
        // 尽管这里进行了很多验证, 但是回复下载的过程还是可能失败, 所以使用try-catch进行完善
        if (shouldResume) {
            // 继续下载任务
            @try {
                downloadTask = [_manager downloadTaskWithResumeData:resumeData progress:request.progressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                } completionHandler:
                                ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    [self handleNetworkResult:downloadTask responseObject:filePath error:error];
                }];
                resumeSucceeded = YES;
            } @catch (NSException *exception) {
                // 恢复下载失败, 直接开启一个全新的下载任务
                ZZHNetworkLog(@"恢复下载失败, reason: %@", exception.reason);
                resumeSucceeded = NO;
            }
        }
        
        //全新的下载任务
        if (!shouldResume) {
            downloadTask = [_manager downloadTaskWithRequest:urlRequest progress:request.progressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];;
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                [self handleNetworkResult:downloadTask responseObject:filePath error:error];
            }];
        }
    }
    
    return downloadTask;
}

#pragma mark - 断点续传路径
// 根据 downloadPath 生成一个对应的 resume path, 在下载中断或取消时resume data会存放在此
- (nullable NSURL *)resumeDataPathForDownloadPath:(nonnull NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5String = [ZZHNetworkUtil MD5String:downloadPath];
    tempPath = [[self tmpDownloadCacheFolder] stringByAppendingPathComponent:md5String];
    return tempPath == nil ? nil : [NSURL fileURLWithPath:tempPath];
}

/// 临时数据的文件夹路径
- (nullable NSString *)tmpDownloadCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    
    static NSString *cacheFolder;
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:@"Incomplete"];
    }

    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        ZZHNetworkLog(@"临时文件路径失败: %@", cacheFolder);
        return nil;
    } else {
        ZZHNetworkLog(@"临时文件路径: %@", cacheFolder);
        return cacheFolder;
    }
}

#pragma mark - other
// 创建 AFHTTPRequestSerializer
- (nonnull AFHTTPRequestSerializer *)requestSerializerForRequest:(nonnull ZZHNetworkRequest *)request {
    AFHTTPRequestSerializer *requestSerializer;
    if (request.requestSerializerType == ZZHNetworkRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == ZZHNetworkRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    } else {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    if (request.requestTimeoutInterval > 0) {
        requestSerializer.timeoutInterval = request.requestTimeoutInterval;
    }
    requestSerializer.allowsCellularAccess = request.allowsCellularAccess;
    
    // If api needs server username and password
    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }

    // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    
    return requestSerializer;
}

- (AFHTTPResponseSerializer *)responseSerializer:(ZZHNetworkResponseSerializerType)type {
    switch (type) {
        case ZZHNetworkResponseSerializerTypeHTTP:
            return [AFHTTPResponseSerializer serializer];
            break;
        case ZZHNetworkResponseSerializerTypeJSON:
            return [AFJSONResponseSerializer serializer];
            break;
        case ZZHNetworkResponseSerializerTypeXMLParser:
            return [AFXMLParserResponseSerializer serializer];
            break;
        default:
            break;
    }
}

/// 结束网络请求必须调用此方法, 清除掉 sessionTask 和 记录字典中的 request
- (void)clearNetworkRequest:(ZZHNetworkRequest *)request {
    request.sessionTask = nil;
    
    // 删除所有的回调block
    [request clearAllBlocks];
    
    Lock();
    [self.requestRecordDic removeObjectForKey:@(request.sessionTask.taskIdentifier)];
    Unlock();
}

// 获取最终URL
- (NSString *)_getRequestUrl:(ZZHNetworkRequest *)request {
    NSParameterAssert(request != nil);
    
    NSString *baseURLString = [request baseURLString] ?: @"";
    NSString *requestURLString = [request requestURLString] ?: @"";
    
    // 如果 requestURLString 是完整地址, 直接使用
    if ([requestURLString hasPrefix:@"http"]) {
        return requestURLString;
    }
    
    // 如果 requestURLString 不完整, 则拼接 baseURL
    if (![baseURLString hasSuffix:@"/"]) {
        baseURLString =  [NSString stringWithFormat:@"%@/", baseURLString?:@""];
    }
    if ([requestURLString hasPrefix:@"/"]) {
        requestURLString = [requestURLString substringFromIndex:1];
    }
    return [NSString stringWithFormat:@"%@%@", baseURLString, requestURLString];
}

// 获取最终参数
- (id)_getFinalParameters:(ZZHNetworkRequest *)request {
    // 参数预处理
    id finalParameters = request.requestParameters;
    if ([request.preprocessor respondsToSelector:@selector(preproccessParameter:)]) {
        finalParameters = [request.preprocessor preproccessParameter:request.requestParameters];
    }
    return finalParameters;
}

@end
