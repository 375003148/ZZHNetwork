//
//  ZZHGetRequest.h
//  ZZHNetwork_Example
//
//  Created by 周子和 on 2020/5/26.
//  Copyright © 2020 375003148. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZHNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZHGetRequest : ZZHNetworkRequest

- (id)initWithUsername:(NSString *)username password:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
