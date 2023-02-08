//
//  ZZHNetworkResponse.h
//  ZZHNetwork
//
//  Created by 周子和 on 2023/2/2.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ZZHNetworkResponseTypeSuccess, //成功
    ZZHNetworkResponseTypeFailure, //失败
    ZZHNetworkResponseTypeCancel,  //取消
} ZZHNetworkResponseType;

@interface ZZHNetworkResponse : NSObject

@property (nonatomic, assign) ZZHNetworkResponseType type;
@property (nonatomic, strong, nullable) id responseObject;
@property (nonatomic, strong, nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END
