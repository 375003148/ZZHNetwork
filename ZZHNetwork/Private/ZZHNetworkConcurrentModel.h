//
//  ZZHNetworkConcurrentModel.h
//  ZZHNetwork
//
//  Created by 周子和 on 2023/2/6.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkRequest.h"
#import "ZZHNetworkDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZHNetworkConcurrentModel : NSObject

@property (nonatomic, strong) ZZHNetworkRequest *request;
@property (nonatomic, copy, nullable) ZZHNetworkSuccessHandler success;
@property (nonatomic, copy, nullable) ZZHNetworkFailHandler failure;

@end

NS_ASSUME_NONNULL_END
