//
//  ZZHViewController.m
//  ZZHNetwork
//
//  Created by 375003148 on 05/26/2020.
//  Copyright (c) 2020 375003148. All rights reserved.
//

#import "ZZHViewController.h"
#import "ZZHGetRequest.h"

@interface ZZHViewController ()

@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation ZZHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _dataArr = @[@"GET", @"POST", @"POST+上传"];
    [self createSubviews];
}

- (void)createSubviews {
    
    for (int i = 0; i < _dataArr.count; ++i) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 300+i;
        btn.frame = CGRectMake(20, 60+i*50, 140, 35);
        [btn setTitle:_dataArr[i] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        // 设置文字颜色
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        
        // 设置背景颜色
        [btn setBackgroundColor:[UIColor blackColor]];
        
        // 设置字体
        [[btn titleLabel] setFont:[UIFont fontWithName:@"Knewave" size:18.0f]];
        
        // Draw a custom gradient
        CAGradientLayer *btnGradient = [CAGradientLayer layer];
        btnGradient.frame = btn.bounds;
        btnGradient.colors = [NSArray arrayWithObjects:
                              (id)[[UIColor colorWithRed:102.0f / 255.0f green:102.0f / 255.0f blue:102.0f / 255.0f alpha:1.0f] CGColor],
                              (id)[[UIColor colorWithRed:51.0f / 255.0f green:51.0f / 255.0f blue:51.0f / 255.0f alpha:1.0f] CGColor],
                              nil];
        [btn.layer insertSublayer:btnGradient atIndex:0];
        
        //设置圆角
        btn.layer.cornerRadius = 5;
        btn.layer.masksToBounds = YES;
        
        //设置边框
        btn.layer.borderColor = [UIColor blackColor].CGColor;
        btn.layer.borderWidth = 1;
        
        [self.view addSubview:btn];
    }
}

- (void)btnClick:(UIButton *)btn {
    switch (btn.tag-300) {
        case 0:
            [self requestForGet];
            break;
        case 1:
            [self requestForPost];
            break;
        case 2:
            [self requestForPostUploadFile];
            break;
        default:
            break;
    }
}

- (void)requestForGet {
    ZZHGetRequest *request = [[ZZHGetRequest alloc] init];
    [request startWithCompleteHandlerOnSuccess:^(id  _Nullable responseObject) {
        //
        NSLog(@"成功: %@", responseObject);
    } failHandler:^(NSError * _Nullable error) {
        //
        NSLog(@"失败: %@", error);
    }];
}

- (void)requestForPost {
    
}

- (void)requestForPostUploadFile {
    
}

@end
