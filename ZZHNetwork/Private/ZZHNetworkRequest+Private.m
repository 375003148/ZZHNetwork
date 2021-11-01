//
//  ZZHNetworkRequest+Private.m
//  ZZHNetwork
//
//  Created by 周子和 on 2021/11/1.
//

#import "ZZHNetworkRequest+Private.h"
#import <objc/runtime.h>

@implementation ZZHNetworkRequest (Private)

static void const *ZZHNetworkSessionTaskKey = &ZZHNetworkSessionTaskKey;

- (void)setSessionTask:(NSURLSessionTask *)sessionTask {
    objc_setAssociatedObject(self, ZZHNetworkSessionTaskKey, sessionTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURLSessionTask *)sessionTask {
    return objc_getAssociatedObject(self, ZZHNetworkSessionTaskKey);
}

@end

