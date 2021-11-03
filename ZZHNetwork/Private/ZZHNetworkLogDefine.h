//
//  ZZHNetworkLogDefine.h
//  ZZHNetwork
//
//  Created by 周子和 on 2021/11/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if DEBUG
#define ZZHNetworkLog(format,...) ZZHNetworkLogFunc(format,##__VA_ARGS__)
#else
#define ZZHNetworkLog(format,...) ;
#endif

void ZZHNetworkLogFunc(NSString *FORMAT, ...);

@interface ZZHNetworkLogDefine : NSObject

+ (BOOL)logEnable;
+ (void)setLogEnable:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END
