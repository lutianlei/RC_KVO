//
//  ViewController.m
//  RC_KVODemo
//
//  Created by lutianlei on 2018/5/18.
//  Copyright © 2018年 Ray. All rights reserved.
//

#import "ViewController.h"
#import "RC_Observer.h"
#import "NSObject+RC_KVO.h"

@interface ViewController ()

@property (strong, nonatomic) RC_Observer *observer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.observer = [RC_Observer new];
    
    [self.observer rc_addObserver:self forKey:@"observedPage" handler:^(id observer, NSString *key, id oldVal, id newVal) {
        NSLog(@"value change");
    }];
    
    self.observer.observedPage = @"10";
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
