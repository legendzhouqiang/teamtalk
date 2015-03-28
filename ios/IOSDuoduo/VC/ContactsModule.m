//
//  ContactsModel.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-21.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "ContactsModule.h"
#import "std.h"
#import "NSDictionary+Safe.h"
#import "DDDepartmentAPI.h"
#import "DDepartment.h"
#import "DDFixedGroupAPI.h"
#import "DDDatabaseUtil.h"
#import "DDGroupModule.h"
#import "RuntimeStatus.h"
#import "DDUserModule.h"
#import "GroupEntity.h"
#import "SpellLibrary.h"
#import "IMBaseDefine.pb.h"
#import "GetDepartment.h"
@implementation ContactsModule
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.groups = [NSMutableArray new];
        self.department = [NSMutableDictionary new];
        [self p_loadAllDepCompletion:^{
            
        }];
    }
    return self;
}


-(void)addContact:(DDUserEntity *)user
{
    
}
/**
 *  按首字母展示
 *
 *  @return 返回界面需要的字典类型
 */
-(NSMutableDictionary *)sortByContactFirstLetter
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    for (DDUserEntity * user in [[DDUserModule shareInstance] getAllMaintanceUser]) {
        
        NSString *fl = [user.pyname substringWithRange:NSMakeRange(0, 1)];
        if ([dic safeObjectForKey:fl]) {
            NSMutableArray *arr = [dic safeObjectForKey:fl];
            [arr addObject:user];
        }else
        {
            NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:@[user]];
            [dic setObject:arr forKey:fl];
        }
    }
    return dic;
}
/**
 *  按部门分类展示
 *
 *  @return 返回界面需要的字典类型
 */
-(NSMutableDictionary *)sortByDepartment
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    for (DDUserEntity * user in [[DDUserModule shareInstance] getAllMaintanceUser]) {
        if ([dic safeObjectForKey:[NSString stringWithFormat:@"%d",user.departId]]) {
            NSMutableArray *arr = [dic safeObjectForKey:[NSString stringWithFormat:@"%d",user.departId]];
            [arr addObject:user];
        }else{
            NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:@[user]];
            [dic safeSetObject:arr forKey:[NSString stringWithFormat:@"%d",user.departId]];
        }
    }
    return dic;
    
}
/**
 *  获取本地收藏的联系人
 *
 *  @return 界面收藏联系人列表
 */
+(NSArray *)getFavContact
{
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *arr = [userDefaults objectForKey:@"favuser"];
    NSMutableArray *contacts = [NSMutableArray new];
    [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [contacts addObject:[DDUserEntity dicToUserEntity:(NSDictionary *)obj]] ;
    }];
    return contacts;
}
/**
 *  收藏联系人接口
 *
 *  @param user 联系人对象
 */
+(void)favContact:(DDUserEntity *)user
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"favuser"] == nil) {
        [userDefaults setObject:@[[DDUserEntity userToDic:user]] forKey:@"favuser"];
    }else
    {
        NSMutableArray *arr = [NSMutableArray arrayWithArray:[userDefaults objectForKey:@"favuser"]];
        if ([arr count] == 0) {
            [arr addObject:[DDUserEntity userToDic:user]];
            [userDefaults setObject:arr forKey:@"favuser"];
            return;
        }
        for (int i = 0;i<[arr count];i++) {
            NSDictionary *dic = [arr objectAtIndex:i];
            if ([[dic objectForKey:@"userId"] isEqualToString: user.objID]) {
                [arr removeObject:dic];
                [userDefaults setObject:arr forKey:@"favuser"];
                return;
            }else
            {
                if ([[arr objectAtIndex:i] isEqualToDictionary:[arr lastObject]]) {
                    [arr addObject:[DDUserEntity userToDic:user]];
                    [userDefaults setObject:arr forKey:@"favuser"];
                    return;
                }
                
            }
        }
        
        
    }
}
/**
 *  检查是否在收藏的联系人里
 *
 *  @param user 用户对象
 *
 *  @return 返回yes表示在收藏的联系人里
 */
-(BOOL)isInFavContactList:(DDUserEntity *)user
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[userDefaults objectForKey:@"favuser"]];
    for (int i = 0;i<[arr count];i++) {
        NSDictionary *dic = [arr objectAtIndex:i];
        if ([[dic objectForKey:@"userId"] integerValue] == user.objID) {
            return YES;
        }
    }
    return NO;
}
+(void)getDepartmentData:(void(^)(id response))block
{
    DDDepartmentAPI* api = [[DDDepartmentAPI alloc] init];
    [api requestWithObject:nil Completion:^(id response, NSError *error) {
        if (!error)
        {
            if (response)
            {
                block(response);
                
            }
            else
            {
                block(nil);
            }
        }
        else
        {
            DDLog(@"error:%@",[error domain]);
            block(nil);
        }
    }];
}
- (void)p_loadAllDepCompletion:(void(^)())completion
{
    __block NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    __block NSInteger version = [[defaults objectForKey:@"allDeplastupdatetime"] integerValue];
    [[DDDatabaseUtil instance] getAllDeprt:^(NSArray *departments, NSError *error) {
        if ([departments count] !=0) {
            [departments enumerateObjectsUsingBlock:^(DepartInfo *obj, NSUInteger idx, BOOL *stop) {
                  [self.department setObject:obj.deptName forKey:[NSString stringWithFormat:@"%d",obj.deptId]];
            }];
        }else{
            version=0;
            GetDepartment* api = [[GetDepartment alloc] init];
            [api requestWithObject:@[@(version)] Completion:^(id response, NSError *error) {
                if (!error)
                {
                    NSUInteger responseVersion = [[response objectForKey:@"allDeplastupdatetime"] integerValue];
                    if (responseVersion == version && responseVersion !=0) {
                        
                        return ;
                        
                    }
                    [defaults setObject:@(responseVersion) forKey:@"allDeplastupdatetime"];
                    NSMutableArray *array = [response objectForKey:@"deplist"];
                    [[DDDatabaseUtil instance] insertDepartments:array completion:^(NSError *error) {
                        
                    }];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [array enumerateObjectsUsingBlock:^(DepartInfo *obj, NSUInteger idx, BOOL *stop) {
                            // [[DDUserModule shareInstance] addMaintanceUser:obj];
                             [self.department setObject:obj.deptName forKey:[NSString stringWithFormat:@"%d",obj.deptId]];
                        }];
                    });
                    
                    
                }
            }];
        }
    }];
    
    GetDepartment* api = [[GetDepartment alloc] init];
    [api requestWithObject:@[@(version)] Completion:^(id response, NSError *error) {
        if (!error)
        {
            NSUInteger responseVersion = [[response objectForKey:@"allDeplastupdatetime"] integerValue];
            if (responseVersion == version && responseVersion !=0) {
                
                return ;
                
            }
            [defaults setObject:@(responseVersion) forKey:@"allDeplastupdatetime"];
            NSMutableArray *array = [response objectForKey:@"deplist"];
            [[DDDatabaseUtil instance] insertDepartments:array completion:^(NSError *error) {
                
            }];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [array enumerateObjectsUsingBlock:^(DepartInfo *obj, NSUInteger idx, BOOL *stop) {
                    //[[DDUserModule shareInstance] addMaintanceUser:obj];
                       [self.department setObject:obj.deptName forKey:[NSString stringWithFormat:@"%d",obj.deptId]];
                }];
            });
            
            
        }
    }];
    
}

@end
