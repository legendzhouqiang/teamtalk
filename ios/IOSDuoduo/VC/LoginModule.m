//
//  DDLoginManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-5.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "LoginModule.h"
#import "DDHttpServer.h"
#import "DDMsgServer.h"
#import "DDTcpServer.h"
#import "SpellLibrary.h"
#import "DDUserModule.h"
#import "DDUserEntity.h"
#import "DDClientState.h"
#import "RuntimeStatus.h"
#import "ContactsModule.h"
#import "DDDatabaseUtil.h"
#import "DDAllUserAPI.h"
#import "LoginAPI.h"
#import "DBManager.h"
@interface LoginModule(privateAPI)

- (void)p_loadAfterHttpServerWithToken:(NSString*)token userID:(NSString*)userID dao:(NSString*)dao password:(NSString*)password uname:(NSString*)uname success:(void(^)(DDUserEntity* loginedUser))success failure:(void(^)(NSString* error))failure;
- (void)reloginAllFlowSuccess:(void(^)())success failure:(void(^)())failure;

@end

@implementation LoginModule
{
    NSString* _lastLoginUser;       //最后登录的用户ID
    NSString* _lastLoginPassword;
    NSString* _lastLoginUserName;
    NSString* _dao;
    NSString * _priorIP;
    NSInteger _port;
    BOOL _relogining;
}
+ (instancetype)instance
{
    static LoginModule *g_LoginManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_LoginManager = [[LoginModule alloc] init];
    });
    return g_LoginManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _httpServer = [[DDHttpServer alloc] init];
        _msgServer = [[DDMsgServer alloc] init];
        _tcpServer = [[DDTcpServer alloc] init];
        _relogining = NO;
    }
    return self;
}


#pragma mark Public API
- (void)loginWithUsername:(NSString*)name password:(NSString*)password success:(void(^)(DDUserEntity* loginedUser))success failure:(void(^)(NSString* error))failure
{

    [_httpServer getMsgIp:^(NSDictionary *dic) {
        NSInteger code  = [[dic objectForKey:@"code"] integerValue];
        if (code == 0) {
            _priorIP = [dic objectForKey:@"priorIP"];
            _port    =  [[dic objectForKey:@"port"] integerValue];
            TheRuntime.msfs=[dic objectForKey:@"msfsPrior"];
            TheRuntime.discoverUrl=[dic objectForKey:@"discovery"];
            [_tcpServer loginTcpServerIP:_priorIP port:_port Success:^{
                [_msgServer checkUserID:name Pwd:password token:@"" success:^(id object) {
                    [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
                    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"username"];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"autologin"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    _lastLoginPassword=password;
                    _lastLoginUserName=name;
                    DDClientState* clientState = [DDClientState shareInstance];
                    clientState.userState=DDUserOnline;
                    _relogining=YES;
                    DDUserEntity* user = object[@"user"];
                    TheRuntime.user=user;
                    [[DDDatabaseUtil instance] openCurrentUserDB];
                    [self p_loadAllUsersCompletion:^{
                        
                    }];
                    success(user);
                     [DDNotificationHelp postNotification:DDNotificationUserLoginSuccess userInfo:nil object:user];
                } failure:^(id object) {
                    DDLog(@"login#登录验证失败");
                    
                    failure(@"登录验证失败");
                }];
                
            } failure:^{
                 DDLog(@"连接消息服务器失败");
                  failure(@"连接消息服务器失败");
            }];
        }
    } failure:^(NSString *error) {
         failure(@"获取消息服务器地址失败");
    }];
    
}

- (void)reloginSuccess:(void(^)())success failure:(void(^)(NSString* error))failure
{
    DDLog(@"relogin fun");
    if ([DDClientState shareInstance].userState == DDUserOffLine && _lastLoginPassword && _lastLoginUserName) {
        
        [self loginWithUsername:_lastLoginUserName password:_lastLoginPassword success:^(DDUserEntity *user) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloginSuccess" object:nil];
            success(YES);
        } failure:^(NSString *error) {
            failure(@"重新登陆失败");
        }];

    }
}

- (void)offlineCompletion:(void(^)())completion
{
    completion();
}



/**
 *  登录成功后获取所有用户
 *
 *  @param completion 异步执行的block
 */
- (void)p_loadAllUsersCompletion:(void(^)())completion
{
    __block NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    __block NSInteger version = [[defaults objectForKey:@"alllastupdatetime"] integerValue];
    [[DDDatabaseUtil instance] getAllUsers:^(NSArray *contacts, NSError *error) {
        if ([contacts count] !=0) {
            [contacts enumerateObjectsUsingBlock:^(DDUserEntity *obj, NSUInteger idx, BOOL *stop) {
                [[DDUserModule shareInstance] addMaintanceUser:obj];
            }];
        }else{
            version=0;
            DDAllUserAPI* api = [[DDAllUserAPI alloc] init];
            [api requestWithObject:@[@(version)] Completion:^(id response, NSError *error) {
                if (!error)
                {
                    NSUInteger responseVersion = [[response objectForKey:@"alllastupdatetime"] integerValue];
                    if (responseVersion == version && responseVersion !=0) {
                        
                        return ;
                        
                    }
                    [defaults setObject:@(responseVersion) forKey:@"alllastupdatetime"];
                    NSMutableArray *array = [response objectForKey:@"userlist"];
                    [[DDDatabaseUtil instance] insertAllUser:array completion:^(NSError *error) {
                        
                    }];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [array enumerateObjectsUsingBlock:^(DDUserEntity *obj, NSUInteger idx, BOOL *stop) {
                            [[DDUserModule shareInstance] addMaintanceUser:obj];
                        }];
                    });
                    
                    
                }
            }];
        }
    }];
    
    DDAllUserAPI* api = [[DDAllUserAPI alloc] init];
    [api requestWithObject:@[@(version)] Completion:^(id response, NSError *error) {
        if (!error)
        {
            NSUInteger responseVersion = [[response objectForKey:@"alllastupdatetime"] integerValue];
            if (responseVersion == version && responseVersion !=0) {
                
                return ;

            }
            [defaults setObject:@(responseVersion) forKey:@"alllastupdatetime"];
            NSMutableArray *array = [response objectForKey:@"userlist"];
            [[DDDatabaseUtil instance] insertAllUser:array completion:^(NSError *error) {
                
            }];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [array enumerateObjectsUsingBlock:^(DDUserEntity *obj, NSUInteger idx, BOOL *stop) {
                    [[DDUserModule shareInstance] addMaintanceUser:obj];
                }];
            });
            
            
        }
    }];
    
}

@end
