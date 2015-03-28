//
//  DDAppDelegate.m
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-23.
//  Copyright (c) 2014年 dujia. All rights reserved.
//
// hunshou modify

#import "DDAppDelegate.h"
#import "LoginViewController.h"
#import "RuntimeStatus.h"
#import "DDClientState.h"
#import "ChattingMainViewController.h"
#import "RuntimeStatus.h"
#import "NSDictionary+Safe.h"
#import "SendPushTokenAPI.h"
#import "DDClientStateMaintenanceManager.h"
#import "std.h"
#import "ChattingMainViewController.h"
#import "SessionEntity.h"
#import "MainViewControll.h"
#import "DDMessageModule.h"
#import "MobClick.h"
#import "LoginModule.h"
#import "DDTcpClientManager.h"
#import "SessionModule.h"
#import <objc/runtime.h>
@interface DDAppDelegate()
@property(assign)BOOL isOpenApp;
@end
@implementation DDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
  
    [DDClientStateMaintenanceManager shareInstance];
     [[NSURLCache sharedURLCache] removeAllCachedResponses];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // for iOS 8
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        // for iOS 7 or iOS 6
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }

    if( SYSTEM_VERSION >=8 ) {
        
        [[UINavigationBar appearance] setTranslucent:YES];
    }
    [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:UITextAttributeTextColor]];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [RuntimeStatus instance];
    
    self.mainViewControll = [MainViewControll new];
    self.nv=self.mainViewControll.nv1;
    LoginViewController *login = [LoginViewController new];
    self.window.rootViewController = login;
    NSDictionary *pushDict = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(pushDict)
    {
        [self application:application didReceiveRemoteNotification:pushDict];
    }

//    self.window.rootViewController = login;
    [self.window makeKeyAndVisible];
  //  [[self class] installCustomFont];
    return YES;
}
+ (void)installCustomFont{
    
  
    SEL systemFontSelector = @selector(systemFontOfSize:);
    Method oldMethod = class_getClassMethod([UIFont class], systemFontSelector);
    Method newMethod = class_getClassMethod([self class], systemFontSelector);
    method_exchangeImplementations(oldMethod, newMethod);  //exchange可用replace替代
    
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize

{
    
    UIFont *font = [UIFont fontWithName:@"FZLanTingHei-L-GBK" size:fontSize];
    
    return font;
    
}


- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}
-(UINavigationController *)mainNavigation{
    return self.nv;
}
- (void)applicationWillResignActive:(UIApplication *)application
{
//    DDClientState* clientState = [DDClientState shareInstance];
//    [clientState setUseStateWithoutObserver:DDUserOffLine];
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
//    DDClientState* clientState = [DDClientState shareInstance];
//    [clientState setUseStateWithoutObserver:DDUserOffLine];
//     self.isOpenApp=NO;
//    [[DDTcpClientManager instance] disconnect];
    if ([[SessionModule sharedInstance]getAllUnreadMessageCount] == 0) {
         [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }else{
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[SessionModule sharedInstance]getAllUnreadMessageCount]];
    }
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

- (void)applicationDidBecomeActive:(UIApplication *)application
{
//    self.isOpenApp=YES;
//    if ([RuntimeStatus instance].user.objID !=nil) {
//        DDClientState* clientState = [DDClientState shareInstance];
//        clientState.userState=DDUserOffLine;
//    }

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DDLog(@"kill the app");
   //程序被杀死调用
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [NSString stringWithFormat:@"%@", deviceToken];
       NSString *dt = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString *dn = [dt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    TheRuntime.pushToken= [dn stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"token......%@",TheRuntime.pushToken);
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSString *error_str = [NSString stringWithFormat: @"%@", error];
    NSLog(@"Failed to get token, error:%@", error_str);
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    
    // 处理推送消息
    UIApplicationState state =application.applicationState;
     if ( state != UIApplicationStateBackground) {
        return;
     }
    NSString *jsonString = [userInfo safeObjectForKey:@"custom"];
    NSData* infoData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* info = [NSJSONSerialization JSONObjectWithData:infoData options:0 error:nil];
    NSInteger from_id =[[info safeObjectForKey:@"from_id"] integerValue];
    SessionType type = (SessionType)[[info safeObjectForKey:@"msg_type"] integerValue];
    NSInteger group_id =[[info safeObjectForKey:@"group_id"] integerValue];
    NSLog(@"推送消息%@",info);
    if (from_id) {
        NSInteger sessionId = type==1?from_id:group_id;
        SessionEntity *session = [[SessionEntity alloc] initWithSessionID:[TheRuntime changeOriginalToLocalID:sessionId SessionType:type] type:type] ;
 
        [[ChattingMainViewController shareInstance] showChattingContentForSession:session];
        //要处理锁屏
        if (![self.mainViewControll.nv1.topViewController isEqual:[ChattingMainViewController shareInstance]])
        {
            
                  [[ChattingMainViewController shareInstance] showChattingContentForSession:session];
                 [self.mainViewControll.nv1 pushViewController:[ChattingMainViewController shareInstance] animated:YES];
            
        }
           }
    NSLog(@"收到推送消息:%@",[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]);
    
}

@end
