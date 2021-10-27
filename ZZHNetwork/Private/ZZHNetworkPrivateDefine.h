//
//  ZZHNetworkPrivateDefine.h
//  ZZHNetwork
//
//  Created by 周子和 on 2020/5/9.
//  Copyright © 2020 周子和. All rights reserved.
//

#import <Foundation/Foundation.h>

#if 0
#define ZZHNetworkLog(FORMAT, ...) fprintf(stderr,"[ZZHNetwork-%s:%d行] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define ZZHNetworkLog(FORMAT, ...) ;
#endif





