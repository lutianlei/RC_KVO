//
//  NextViewController.m
//  RC_KVODemo
//
//  Created by lutianlei on 2018/5/29.
//  Copyright © 2018年 Ray. All rights reserved.
//

#import "NextViewController.h"
#import "NSObject+RC_KVO.h"
#import "RC_Observer.h"


@interface NextViewController ()

@property (strong, nonatomic) RC_Observer *observer;

@end

@implementation NextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.observer = [RC_Observer new];
    [self.observer rc_addObserver:self forKey:@"observedPage" handler:^(id observer, NSString *key, id oldVal, id newVal) {
        NSLog(@"value change next");
    }];
    self.observer.observedPage = @"20";
    
    [self.observer rc_addObserver:self forKey:@"observedNum" handler:^(id observer, NSString *key, id oldVal, id newVal) {
        NSLog(@"value change next");
    }];
    self.observer.observedPage = @"120";
}


- (void)dealloc{
    [self.observer rc_removeObserver:self forKey:@"observedPage"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
