//
//  ZZHNetworkLog.m
//  ZZHNetwork
//
//  Created by 周子和 on 2023/1/3.
//

#import "ZZHNetworkLog.h"
#import "ZZHNetworkRequest+Private.h"

@implementation ZZHNetworkLog

// 打印网络请求开始(包括URL,请求参数)
+ (void)logRequestStart:(ZZHNetworkRequest *)request {
#if DEBUG
    // 打印
    if (request.logLevel >= 0) {
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@">>>>>>>>>> 网络请求开始 <<<<<<<<<<"];
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@"请求URL -> %@", [request getFinalURL]];
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@"请求参数 -> %@", [request getFinalParameters]];
        if (request.logLevel > 0) {
            [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@"请求header -> %@", request.sessionTask.currentRequest.allHTTPHeaderFields];
        }
        [ZZHNetworkLog _logSpaceLine];
    }
#else
#endif
}

/// 打印网络请求原始返回数据
+ (void)logRequestResponse:(nonnull ZZHNetworkRequest *)request
            responseObject:(nullable id)responseObject
                     error:(nullable NSError *)error {
#if DEBUG
    // 打印
    if (request.logLevel > 0) {
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@">>>>>>>>>> 网络请求原始返回数据 <<<<<<<<<<"];
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@"responseObject -> %@", responseObject];
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@"nerror -> %@", error];
        [ZZHNetworkLog _logSpaceLine];
    }
#else
#endif
}

/// 打印网络请求成功的最终数据
+ (void)logSuccess:(nonnull ZZHNetworkRequest *)request responseObject:(nullable id)responseObject {
#if DEBUG
    if (request.logLevel >= 0) {
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@">>>>>>>>>> 网络请求成功 <<<<<<<<<<"];
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@"responseObject -> %@", responseObject];
        [ZZHNetworkLog _logSpaceLine];
    }
#else
#endif
}

/// 打印网络请求失败的最终数据
+ (void)logFailure:(nonnull ZZHNetworkRequest *)request error:(nullable NSError *)error {
#if DEBUG
    if (request.logLevel >= 0) {
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@">>>>>>>>>> 网络请求失败 <<<<<<<<<<"];
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:@"error -> %@", error];
        [ZZHNetworkLog _logSpaceLine];
    }
#else
#endif
}

+ (void)logRequest:(nonnull ZZHNetworkRequest *)request mes:(NSString *)mes, ... {
#if DEBUG
    if (request.logLevel >= 0) {
        [ZZHNetworkLog _log:request.sessionTask.taskIdentifier mes:mes];
        [ZZHNetworkLog _logSpaceLine];
    }
#else
#endif
}

#pragma mark - Private

+ (void)_log:(NSUInteger)requestID mes:(NSString *)FORMAT, ... {
#if DEBUG
    va_list arglist;
    va_start(arglist, FORMAT);
    NSString *outStr = [[NSString alloc] initWithFormat:FORMAT arguments:arglist];
    va_end(arglist);
    
    if (requestID) {
        NSString *requestIDStr = [NSString stringWithFormat:@"%lu", requestID];
        fprintf(stderr,"[ZZHNetwork][ID:%s] %s\n", [requestIDStr UTF8String], [outStr UTF8String]);
    } else {
        fprintf(stderr,"[ZZHNetwork] %s\n", [outStr UTF8String]);
    }
    
    //    fprintf(stderr,"[%s:%d] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
    return;
#endif
}

+ (void)_logSpaceLine {
#if DEBUG
    fprintf(stderr,"\n");
#else
    return;
#endif
}


//#if DEBUG
//#define ZZHNetworkLog(FORMAT, ...) fprintf(stderr,"[%s:%d] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
//#else
//#define ZZHNetworkLog(FORMAT,...) ;
//#endif
//
//#if DEBUG
//#define ZZHNetworkLogSpace() fprintf(stderr,"\n");
//#else
//#define ZZHNetworkLogSpace() ;
//#endif

@end
