//
//  ZZHNetworkAgent.m
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/6.
//  Copyright © 2020 周子和. All rights reserved.
//

#import "ZZHNetworkAgent.h"
#import "AFNetworking.h"
#import "ZZHNetworkRequest.h"
#import <pthread/pthread.h>
#import "ZZHNetworkUtil.h"
#import "ZZHNetworkPrivateDefine.h"
//#import "ZZHNetworkRequest+Private.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

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

- (void)resumeRequest:(nonnull ZZHNetworkRequest *)request {
    NSParameterAssert(request != nil);
    
    if (request.isExecuting) {
        return;
    } else {
        // 创建一个新的请求任务
        NSError * __autoreleasing requestError = nil;
        NSURLSessionTask *sessionTask = [self sessionTaskForRequest:request error:&requestError];
        if (requestError) {
            //创建task失败, 进行error回调
            [self handleFailResult:request error:requestError];
            return;
        }
        request.sessionTask = sessionTask;
        //    // 设置task优先级, 适用于 iOS 8 +
        //    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        //        switch (request.requestPriority) {
        //            case YTKRequestPriorityHigh:
        //                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
        //                break;
        //            case YTKRequestPriorityLow:
        //                request.requestTask.priority = NSURLSessionTaskPriorityLow;
        //                break;
        //            case YTKRequestPriorityDefault:
        //                /*!!fall through*/
        //            default:
        //                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
        //                break;
        //        }
        //    }
        
        // 存储request记录
        [self addRequestToRecord:request];
        
        //开启任务
        [request.sessionTask resume];
    }
}

- (void)cancelRequest:(nonnull ZZHNetworkRequest *)request {
    NSParameterAssert(request != nil);
    
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
    
    //删除request记录
    [self removeRequestFromRecord:request];
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

#pragma mark - Private Method - 处理request结果
/// 这里注意, 由于 init 方法中给 _manager.completionQueue 赋值了一个并发队列, 所以以下的回调方法都是在子线程中进行的, 需要注意线程安全

- (void)handleRequestResult:(nullable NSURLSessionTask *)task responseObject:(nullable id)responseObject error:(nullable NSError *)error {
    Lock();
    ZZHNetworkRequest *request = _requestRecordDic[@(task.taskIdentifier)];
    Unlock();

    //这里很重要 !!!
    // request取消时, 也会进入这个回调, 此情况下 request为nil.
    // 在这种情况下不进行任何回调操作
    if (!request) {
        ZZHNetworkLog(@"[ZZHNetworkLog]: 网络任务被取消了");
        return;
    }

    ZZHNetworkLog(@"[ZZHNetworkLog]: 网络Task完成, 进行回调, 当前Request: %@", NSStringFromClass([request class]));
    
    // 将数据进行格式转换, 并存储在request中
    NSError * __autoreleasing serializationError = nil;
    request.responseObject = responseObject;
    if ([responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[ZZHNetworkUtil stringEncodingWithRespond:task.response]];
        if (request.responseSerializerType != ZZHNetworkResponseSerializerTypeHTTP) {
            //根据不同的格式进行数据格式转换
            request.responseObject = [[self responseSerializer:request.responseSerializerType] responseObjectForResponse:task.response data:request.responseData error:&serializationError];
        } else {
            //HTTP格式时,已经默认情况下做过了转换, 此时不需要再做啥
        }
    }
    
    //最终判断失败还是成功, 然后进行各自的回调操作
    NSError *requestError = nil;
    BOOL succeed = NO;
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = YES;
    }

    if (succeed) {
        [self handleSuccessResult:request];
    } else {
        [self handleFailResult:request error:requestError];
    }

    //回调之后清除相关数据
    dispatch_main_async_safe(^{
        [self removeRequestFromRecord:request];
    });
}

//处理成功的回调
- (void)handleSuccessResult:(nonnull ZZHNetworkRequest *)request {
    dispatch_main_async_safe(^{
        if (request.successHandler) {
            //block
            request.successHandler(request.responseObject);
        }
        if (request.delegate && [request.delegate respondsToSelector:@selector(requestDidSucceed:)]) {
            //deledate
            [request.delegate requestDidSucceed:request];
        }
    });
}

//处理失败的回调 (所有的error情况时都调用此方法, 无论有没有开始网络请求)
- (void)handleFailResult:(nonnull ZZHNetworkRequest *)request error:(NSError *)error {
    request.error = error;
    
    // 处理下载失败时存储已经下载的数据
    // 下载失败时将 resume data 存放在 resume path 下
    if (request.resumableDownloadPath) {
        NSURL *tmpDownloadPath = [self resumeDataPathForDownloadPath:request.resumableDownloadPath];
        NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
        if (tmpDownloadPath && resumeData) {
            [resumeData writeToURL:tmpDownloadPath atomically:YES];
        }
    }
    //下载失败时, 将数据存在request.responseData返回给外层, 并且删除掉下载路径下的数据
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[ZZHNetworkUtil stringEncodingWithRespond:request.sessionTask.response]];
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    
    //主线程进行回调
    dispatch_main_async_safe(^{
        if (request.failHandler) {
            request.failHandler(error);
        }
        if (request.delegate && [request.delegate respondsToSelector:@selector(requestDidFailed:)]) {
            [request.delegate requestDidFailed:request];
        }
    });
}


#pragma mark - other

// 创建 AFHTTPRequestSerializer
- (AFHTTPRequestSerializer *)requestSerializerForRequest:(nonnull ZZHNetworkRequest *)request {
    AFHTTPRequestSerializer *requestSerializer;
    if (request.requestSerializerType == ZZHNetworkRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == ZZHNetworkRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    } else {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    requestSerializer.timeoutInterval = request.requestTimeoutInterval;
    requestSerializer.allowsCellularAccess = request.allowsCellularAccess;
    
//#warning 这里
//    // If api needs server username and password
//    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
//    if (authorizationHeaderFieldArray != nil) {
//        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
//                                                          password:authorizationHeaderFieldArray.lastObject];
    
    
//    // If api needs to add custom value to HTTPHeaderField
//    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
//    if (headerFieldValueDictionary != nil) {
//        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
//            NSString *value = headerFieldValueDictionary[httpHeaderField];
//            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
//        }
//    }
    
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

- (void)addRequestToRecord:(ZZHNetworkRequest *)request {
    Lock();
    _requestRecordDic[@(request.sessionTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(ZZHNetworkRequest *)request {
    Lock();
    [_requestRecordDic removeObjectForKey:@(request.sessionTask.taskIdentifier)];
    Unlock();
    
    //删除完记录记得把sessionTask置为nil. (很重要)
    request.sessionTask = nil;
    request.successHandler = nil;
    request.failHandler = nil;
}

#pragma mark - 创建网络任务 sessionTask

//创建session的入口方法
- (NSURLSessionTask *)sessionTaskForRequest:(nonnull ZZHNetworkRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    NSString *urlStr = request.requestURLString?:@"";
    NSDictionary *parameters = request.requestParameters?:@{};

    ZZHNetworkRequestType requestType = request.requestType;
    if (requestType == ZZHNetworkRequestTypeGet && request.resumableDownloadPath) {
        //断点下载
        return [self downloadTaskWithDownloadPath:request.resumableDownloadPath requestSerializer:requestSerializer URLString:urlStr parameters:parameters progress:request.progressBlock error:error];
    } else {
        //其它
        return [self dataTaskWithHTTPMethod:requestType requestSerializer:requestSerializer URLString:urlStr parameters:parameters progress:request.progressBlock constructingBodyWithBlock:request.constructingBlock error:error];
    }
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(ZZHNetworkRequestType)type
        requestSerializer:(nonnull AFHTTPRequestSerializer *)requestSerializer
                URLString:(nonnull NSString *)URLString
               parameters:(nonnull id)parameters
                 progress:(nullable ZZHNetworkProgress)progress
constructingBodyWithBlock:(nullable ZZHConstructingBlock)constructBlock
                    error:(NSError * _Nullable __autoreleasing *)error {
    
    NSString *methodName;
    ZZHNetworkProgress downloadProgress = nil;
    ZZHNetworkProgress uploadProgress = nil;
    switch (type) {
        case ZZHNetworkRequestTypeGet: {
            methodName = @"GET";
            downloadProgress = progress;
        }
            break;
        case ZZHNetworkRequestTypePost: {
            methodName = @"POST";
            uploadProgress = progress;
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
    NSMutableURLRequest *request = nil;
    if (constructBlock) {
        request = [requestSerializer multipartFormRequestWithMethod:methodName URLString:URLString parameters:parameters constructingBodyWithBlock:constructBlock error:error];
    } else {
        request = [requestSerializer requestWithMethod:methodName URLString:URLString parameters:parameters error:error];
    }

    //构架dataTask
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request uploadProgress:uploadProgress downloadProgress:downloadProgress completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [self handleRequestResult:dataTask responseObject:responseObject error:error];
    }];
    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(nonnull NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {

    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];

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
                downloadTask = [_manager downloadTaskWithResumeData:resumeData progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                } completionHandler:
                                ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                    [self handleRequestResult:downloadTask responseObject:filePath error:error];
                                }];
                resumeSucceeded = YES;
            } @catch (NSException *exception) {
                // 恢复下载失败, 直接开启一个全新的下载任务
                ZZHNetworkLog(@"[ZZHNetworkLog]: Resume download failed, reason = %@", exception.reason);
                resumeSucceeded = NO;
            }
        }
        
        //全新的下载任务
        if (!shouldResume) {
            downloadTask = [_manager downloadTaskWithRequest:urlRequest progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];;
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                [self handleRequestResult:downloadTask responseObject:filePath error:error];
            }];
        }
    }
    
    return downloadTask;
}

#pragma mark - 断点续传 Resumable Download

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
        ZZHNetworkLog(@"[ZZHNetworkLog]: Failed to create cache directory at %@", cacheFolder);
        return nil;
    } else {
        ZZHNetworkLog(@"[ZZHNetworkLog]: %@", cacheFolder);
        return cacheFolder;
    }
}

@end
