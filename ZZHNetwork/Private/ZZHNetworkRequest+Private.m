//
//  ZZHNetworkRequest+Private.m
//  ZZHNetwork
//
//  Created by 周子和 on 2021/11/1.
//

#import "ZZHNetworkRequest+Private.h"
#import "ZZHNetworkUtil.h"
#import "ZZHNetworkLog.h"
#import <objc/runtime.h>

@interface ZZHNetworkRequest ()

/// 最终的请求参数
@property (nonatomic, strong, readwrite) NSDictionary *finalParameters;


@end

@implementation ZZHNetworkRequest (Private)

// 获取最终URL
- (NSString *)getFinalURL {
    NSString *baseURLString = self.baseURLString?:@"";
    NSString *requestURLString = self.requestURLString?:@"";
    
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
- (id)saveFinalParameters {
    // 参数预处理
    id finalParameters = self.requestParameters;
    if ([self.preprocessor respondsToSelector:@selector(preproccessParameter:)]) {
        finalParameters = [self.preprocessor preproccessParameter:self.requestParameters];
    }
    self.finalParameters = finalParameters;
    return finalParameters;
}

#pragma mark - 断点续传路径

// 根据 downloadPath 生成一个对应的 resume path, 在下载中断或取消时resume data会存放在此
- (nullable NSURL *)resumeDataPath {
    // 获取缓存文件夹
    NSString *cacheFolder = [self tmpDownloadCacheFolder];
    
    if (cacheFolder) {
        NSString *md5String = [ZZHNetworkUtil MD5String:self.resumableDownloadPath];
        NSString *tmpPath = [[self tmpDownloadCacheFolder] stringByAppendingPathComponent:md5String];
        NSURL *result = tmpPath ? [NSURL fileURLWithPath:tmpPath] : nil;
        [ZZHNetworkLog logRequest:self mes:@"临时文件存储完整路径: %@", result];
        
        return result;
        
    } else {
        return nil;
    }
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
        [ZZHNetworkLog logRequest:self mes:@"临时文件夹路径创建失败: %@, /error/ -> %@", cacheFolder, error];
        return nil;
    } else {
        return cacheFolder;
    }
}

#pragma mark - set && get

static void const *ZZHNetworkSessionTaskKey = &ZZHNetworkSessionTaskKey;
static void const *ZZHNetworkExecutingKey = &ZZHNetworkExecutingKey;
static void const *ZZHNetworkFinalPramsKey = &ZZHNetworkFinalPramsKey;

- (void)setFinalParameters:(NSDictionary *)finalParameters {
    objc_setAssociatedObject(self, ZZHNetworkFinalPramsKey, finalParameters, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)finalParameters {
    return objc_getAssociatedObject(self, ZZHNetworkFinalPramsKey);
}

- (void)setSessionTask:(NSURLSessionTask *)sessionTask {
    objc_setAssociatedObject(self, ZZHNetworkSessionTaskKey, sessionTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURLSessionTask *)sessionTask {
    return objc_getAssociatedObject(self, ZZHNetworkSessionTaskKey);
}

- (void)setExecuting:(BOOL)executing {
    objc_setAssociatedObject(self, ZZHNetworkExecutingKey, @(executing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)executing {
    NSNumber *result = objc_getAssociatedObject(self, ZZHNetworkExecutingKey);
    return  [result boolValue];
}

@end

