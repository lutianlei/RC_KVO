//
//  NSObject+RC_KVO.h
//  RC_KVODemo
//
//  Created by lutianlei on 2018/5/18.
//  Copyright © 2018年 Ray. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RC_KVOObserverHandler)(id observer, NSString *key, id oldVal, id newVal);

@interface NSObject (RC_KVO)

/**
 add observer

 @param observer 监听者
 @param key 被监听者属性
 @param handler 回调事件
 */
- (void)rc_addObserver:(NSObject *)observer forKey:(NSString *)key handler:(RC_KVOObserverHandler)handler;


/**
 remove

 @param observer 监听者
 @param key 被监听者属性
 */
- (void)rc_removeObserver:(NSObject *)observer forKey:(NSString *)key;

/**
 remove
 
 @param observer 监听者
 */
- (void)rc_removeObserver:(NSObject *)observer;
@end
