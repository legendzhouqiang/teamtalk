//
//  DDEmotionsModule.m
//  Mogujie4iPhone
//
//  Created by 独嘉 on 14-6-23.
//  Copyright (c) 2014年 juangua. All rights reserved.
//

#import "EmotionsModule.h"

@implementation EmotionsModule
{
//    NSDictionary* _emotionUnicodeDic;
//    NSDictionary* _unicodeEmotionDic;
//    NSArray* _emotions;
}

+ (instancetype)shareInstance
{
    static EmotionsModule* g_emotionsModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_emotionsModule = [[EmotionsModule alloc] init];
        
    });
    return g_emotionsModule;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _emotionUnicodeDic = @{@"[牙牙撒花]":@"221.gif",
                               @"[牙牙尴尬]":@"222.gif",
                               @"[牙牙大笑]":@"223.gif",
                               @"[牙牙组团]":@"224.gif",
                               @"[牙牙凄凉]":@"225.gif",
                               @"[牙牙吐血]":@"226.gif",
                               @"[牙牙花痴]":@"227.gif",
                               @"[牙牙疑问]":@"228.gif",
                               @"[牙牙爱心]":@"229.gif",
                               @"[牙牙害羞]":@"230.gif",
                               @"[牙牙牙买碟]":@"231.gif",
                               @"[牙牙亲一下]":@"232.gif",
                               @"[牙牙大哭]":@"233.gif",
                               @"[牙牙愤怒]":@"234.gif",
                               @"[牙牙挖鼻屎]":@"235.gif",
                               @"[牙牙嘻嘻]":@"236.gif",
                               @"[牙牙漂漂]":@"237.gif",
                               @"[牙牙冰冻]":@"238.gif",
                               @"[牙牙傲娇]":@"239.gif",
                             
                               };
        _unicodeEmotionDic = [[NSMutableDictionary alloc] init];
        [_emotionUnicodeDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [_unicodeEmotionDic setValue:key forKey:obj];
        }];
        _emotions = [[NSMutableArray alloc] initWithArray:[_emotionUnicodeDic allKeys]];
        
        _emotionLength = [[NSMutableDictionary alloc] init];
        [_emotions enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            NSString *string = _emotionUnicodeDic[obj];
            [_emotionLength setValue:@([string length]) forKeyPath:obj];
        }];
    }
    return self;
}
@end
