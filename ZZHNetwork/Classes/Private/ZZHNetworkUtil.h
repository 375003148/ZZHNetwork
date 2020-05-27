//
//  ZZHNetworkUtil.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/9.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZHNetworkUtil : NSObject

/// 根据response选择字符串编码
+ (NSStringEncoding)stringEncodingWithRespond:(nullable NSURLResponse *)response;

/// 验证断点下载时数据的有效性
/// @param data 断点下载时已经存在的数据
+ (BOOL)validateResumeData:(nullable NSData *)data;

/// 将字符串进行MD5
/// @param string 传入要处理的字符串
+ (nonnull NSString *)MD5String:(nullable NSString *)string;

@end

NS_ASSUME_NONNULL_END
