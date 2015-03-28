//
//  DDUserModule.m
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-26.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "DDUserModule.h"
#import "DDDatabaseUtil.h"
@interface DDUserModule(PrivateAPI)

- (void)n_receiveUserLogoutNotification:(NSNotification*)notification;
- (void)n_receiveUserLoginNotification:(NSNotification*)notification;
@end

@implementation DDUserModule
{
    NSMutableDictionary* _allUsers;
}

+ (instancetype)shareInstance
{
    static DDUserModule* g_userModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_userModule = [[DDUserModule alloc] init];
    });
    return g_userModule;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _allUsers = [[NSMutableDictionary alloc] init];
        _recentUsers = [[NSMutableDictionary alloc] init];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveUserLogoutNotification:) name:MGJUserDidLogoutNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveUserLoginNotification:) name:DDNotificationUserLoginSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveUserLoginNotification:) name:DDNotificationUserReloginSuccess object:nil];
        

    }
    return self;
}


- (void)addMaintanceUser:(DDUserEntity*)user
{
    
    if (!user)
    {
        return;
    }
    if (!_allUsers)
    {
        _allUsers = [[NSMutableDictionary alloc] init];
    }
    [_allUsers setValue:user forKey:user.objID];
    
}
-(NSArray *)getAllMaintanceUser
{
    return [_allUsers allValues];
}
- (void )getUserForUserID:(NSString*)userID Block:(void(^)(DDUserEntity *user))block
{
    return block(_allUsers[userID]);

}

- (void)addRecentUser:(DDUserEntity*)user
{
    if (!user)
    {
        return;
    }
    if (!self.recentUsers)
    {
        self.recentUsers = [[NSMutableDictionary alloc] init];
    }
    NSArray* allKeys = [self.recentUsers allKeys];
    if (![allKeys containsObject:user.objID])
    {
        [self.recentUsers setValue:user forKey:user.objID];
        [[DDDatabaseUtil instance] insertUsers:@[user] completion:^(NSError *error) {
            
        }];
    }
   
}


- (void)loadAllRecentUsers:(DDLoadRecentUsersCompletion)completion
{
    
    //加载本地最近联系人
    }

#pragma mark - 
#pragma mark PrivateAPI
- (void)n_receiveUserLogoutNotification:(NSNotification*)notification
{
    //用户登出
    _recentUsers = nil;
}

- (void)n_receiveUserLoginNotification:(NSNotification*)notification
{
    if (!_recentUsers)
    {
        _recentUsers = [[NSMutableDictionary alloc] init];
        [self loadAllRecentUsers:^{
            [DDNotificationHelp postNotification:DDNotificationRecentContactsUpdate userInfo:nil object:nil];
        }];
    }
}

-(void)clearRecentUser
{
    DDUserModule* userModule = [DDUserModule shareInstance];
    [[userModule recentUsers] removeAllObjects];
}

@end
