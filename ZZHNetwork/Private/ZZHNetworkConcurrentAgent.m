//
//  ZZHNetworkConcurrentAgent.m
//  ZZHNetwork
//
//  Created by 周子和 on 2023/2/2.
//

#import "ZZHNetworkConcurrentAgent.h"

@interface ZZHNetworkConcurrentAgent()

@property (strong, nonatomic) NSMutableArray<ZZHNetworkConcurrentRequest *> *requestArray;

@end


@implementation ZZHNetworkConcurrentAgent

+ (ZZHNetworkConcurrentAgent *)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addConcurrentRequest:(ZZHNetworkConcurrentRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeConcurrentRequest:(ZZHNetworkConcurrentRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end
