//
//  ZZHNetworkConcurrentAgent.h
//  ZZHNetwork
//
//  Created by 周子和 on 2023/2/2.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkConcurrentRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZHNetworkConcurrentAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (ZZHNetworkConcurrentAgent *)sharedAgent;

- (void)addConcurrentRequest:(ZZHNetworkConcurrentRequest *)request;

- (void)removeConcurrentRequest:(ZZHNetworkConcurrentRequest *)request;


@end

NS_ASSUME_NONNULL_END
