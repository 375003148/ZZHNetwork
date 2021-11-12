//
//  ZZHNetworkLogDefine.h
//  ZZHNetwork
//
//  Created by 周子和 on 2021/11/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if DEBUG
#define ZZHNetworkLog(FORMAT, ...) fprintf(stderr,"[%s:%d] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define ZZHNetworkLog(FORMAT,...) ;
#endif

#if DEBUG
#define ZZHNetworkLogSpace() fprintf(stderr,"\n");
#else
#define ZZHNetworkLogSpace() ;
#endif


NS_ASSUME_NONNULL_END
