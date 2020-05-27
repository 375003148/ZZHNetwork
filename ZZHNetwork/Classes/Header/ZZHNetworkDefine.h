//
//  ZZHNetworkDefine.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/6.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ZZHNetworkRequestType) {
    ZZHNetworkRequestTypePost = 0,
    ZZHNetworkRequestTypeGet,
    ZZHNetworkRequestTypeHEAD,
    ZZHNetworkRequestTypePUT,
    ZZHNetworkRequestTypeDELETE,
    ZZHNetworkRequestTypePATCH,
};

typedef NS_ENUM(NSUInteger, ZZHNetworkRequestSerializerType) {
    ZZHNetworkRequestSerializerTypeHTTP = 0,
    ZZHNetworkRequestSerializerTypeJSON,
};

typedef NS_ENUM(NSUInteger, ZZHNetworkResponseSerializerType) {
    /// NSData
    ZZHNetworkResponseSerializerTypeHTTP = 0,
    /// JSON
    ZZHNetworkResponseSerializerTypeJSON,
    /// XMLParser
    ZZHNetworkResponseSerializerTypeXMLParser
};

typedef void (^ZZHNetworkSuccessHandler)(id _Nullable responseObject);
typedef void (^ZZHNetworkFailHandler)(NSError * _Nullable error);
typedef void (^ZZHNetworkProgress)(NSProgress * _Nullable progress);


#pragma mark - 代理

@class ZZHNetworkRequest;
@protocol ZZHNeteorkRequestCallBackDeledate <NSObject>

@optional

/// 网络请求成功的回调
/// @param request 创建的ZZHNetworkRequest
- (void)requestDidSucceed:(__kindof ZZHNetworkRequest *_Nonnull)request;

/// 网络请求失败的回调
/// @param request 创建的ZZHNetworkRequest
- (void)requestDidFailed:(__kindof ZZHNetworkRequest *_Nonnull)request;

@end
