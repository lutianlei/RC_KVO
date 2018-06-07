//
//  NSObject+RC_KVO.m
//  RC_KVODemo
//
//  Created by lutianlei on 2018/5/18.
//  Copyright © 2018年 Ray. All rights reserved.
//

#import "NSObject+RC_KVO.h"
#import <objc/message.h>

static NSString *const RCKVOPrefix = @"RCKVOPrefix_";
static NSString *const RCKVOObserveAssociate = @"RCKVOObserveAssociate";

@interface RC_ObserverInfo : NSObject

@property (weak, nonatomic) NSObject *observer;
@property (copy, nonatomic) NSString *key;
@property (copy, nonatomic) RC_KVOObserverHandler handler;

@end

@implementation RC_ObserverInfo

- (instancetype)initWithObserver:(NSObject *)observer key:(NSString *)key handler:(RC_KVOObserverHandler)handler{
    self = [super init];
    if (self) {
        self.observer = observer;
        self.key = key;
        self.handler = handler;
    }
    return self;
}

@end


// getter to setter
static NSString *setterForGetter(NSString *getter){
    if (getter.length <= 0) { return nil;}

    // 根据key获取setter方法的string(setObservedPage)
    // 获取首字符，并转大写
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    // 获取首字符之后的字符串
    NSString *remainString = [getter substringFromIndex:1];
    // 拼接setter方法
    NSString *setterMethodString = [NSString stringWithFormat:@"set%@%@:",firstString,remainString];
    return setterMethodString;
}
// setter to getter
static NSString *getterForSetter(NSString *setter){
    if (setter.length <= 0 || ![setter hasPrefix: @"set"] || ![setter hasSuffix: @":"]) {return nil;}
    
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString * getter = [setter substringWithRange: range];
    
    NSString * firstString = [[getter substringToIndex: 1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: firstString];
    
    return getter;
}

// 重写setter 方法
static void KVO_Setter(id self,SEL _cmd, id newValue){
    NSLog(@"%s",__func__);
    NSString * setterName = NSStringFromSelector(_cmd);
    NSString * getterName = getterForSetter(setterName);
    
    id oldValue = [self valueForKey: getterName];
    
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    [self willChangeValueForKey: getterName];
    void (*objc_msgSendSuperKVO)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperKVO(&superClass, _cmd, newValue);
    [self didChangeValueForKey: getterName];

    // 获取监听回调
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(RCKVOObserveAssociate));
    if (observers) {
        for (RC_ObserverInfo *info in observers) {
            if ([info.key isEqualToString:getterName]) {
                dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    info.handler(self, getterName, oldValue, newValue);
                });
            }
        }
    }
    
}

@implementation NSObject (RC_KVO)

- (void)rc_addObserver:(NSObject *)observer forKey:(NSString *)key handler:(RC_KVOObserverHandler)handler{
    // 首先判断监听的对象属性setter方法有没有实现，此步判断监听属性是否正确
    SEL selectorSetter = NSSelectorFromString(setterForGetter(key));
    Method setterMethod = class_getInstanceMethod([self class], selectorSetter);
    if (!setterMethod) {
        // 可抛出异常
        return;
    }
    // 先判断当前class是否已经创建
    // 如果子类已经创建，self 原本指向父类的isa指针指向子类 通过object_getClass可以获取
    Class observerClass = object_getClass(self);
    NSString *className = NSStringFromClass(observerClass);
    if (![className hasPrefix:RCKVOPrefix]) {
        // 创建子类
        observerClass = [self createKVOClassOfOriginalClassName:className];
        // 将self的isa指针只想kvoClass
        object_setClass(self, observerClass);
    }
    
    // 重写setter方法 先判断是否实现了setter方法，没有实现则add
    if (![self hasSelector:selectorSetter]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(observerClass, selectorSetter, (IMP)KVO_Setter, types);
    }
    
    
    //
    RC_ObserverInfo *info = [[RC_ObserverInfo alloc] initWithObserver:observer key:key handler:handler];
    
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(RCKVOObserveAssociate));
    // 是否关联
    if (!observers) {
        observers = [NSMutableArray new];
        objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(RCKVOObserveAssociate), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
    
}

- (void)rc_removeObserver:(NSObject *)observer forKey:(NSString *)key{
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(RCKVOObserveAssociate));
    if (observers) {
        if (!key) {
            [observers removeAllObjects];
        }else{
            RC_ObserverInfo *removeInfo = nil;
            for (RC_ObserverInfo *info in observers) {
                
                if ([info.key isEqualToString:key] && info.observer == observer) {
                    removeInfo = info;
                    break;
                }
                
            }
            
            [observers removeObject:removeInfo];
        }
    }
}

- (void)rc_removeObserver:(NSObject *)observer{
    [self rc_removeObserver:observer forKey:nil];
}

- (Class)createKVOClassOfOriginalClassName:(NSString *)originalClassName{
    
    // 拼接子类classnamestring
    NSString *kvoClassName = [RCKVOPrefix stringByAppendingString:originalClassName];
    
    // 父类class
    Class originalClass = NSClassFromString(originalClassName);
    // param：父类class； 子类classnamestring（char *）
    //  初始化 kvoclass
    Class kvoClass = objc_allocateClassPair(originalClass, kvoClassName.UTF8String, 0);
    
    return kvoClass;
    
}

- (BOOL)hasSelector:(SEL)selector{
    Class observerClass = object_getClass(self);
    unsigned int outCout = 0;
    Method *methodList = class_copyMethodList(observerClass,&outCout);
    
    for (int i = 0; i < outCout; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector ) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;

}



@end
