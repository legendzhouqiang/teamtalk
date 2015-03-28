//
//  DDGroupModule.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-08-11.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "DDGroupModule.h"
#import "RuntimeStatus.h"
#import "GetGroupInfoAPi.h"
#import "DDReceiveGroupAddMemberAPI.h"
#import "DDDatabaseUtil.h"
#import "GroupAvatarImage.h"
#import "DDNotificationHelp.h"
#import "NSDictionary+Safe.h"
@implementation DDGroupModule
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.allGroups = [NSMutableDictionary new];
        [[DDDatabaseUtil instance] loadGroupsCompletion:^(NSArray *contacts, NSError *error) {
            [contacts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                GroupEntity *group = (GroupEntity *)obj;
                if(group.objID)
                {
                    [self addGroup:group];
                    GetGroupInfoAPI* request = [[GetGroupInfoAPI alloc] init];
                    [request requestWithObject:@[@([TheRuntime changeIDToOriginal:group.objID]),@(group.objectVersion)] Completion:^(id response, NSError *error) {
                        if (!error)
                        {
                            if ([response count]) {
                                GroupEntity* group = (GroupEntity*)response[0];
                                if (group)
                                {
                                    [self addGroup:group];
                                    [[DDDatabaseUtil instance] updateRecentGroup:group completion:^(NSError *error) {
                                        DDLog(@"insert group to database error.");
                                    }];
                                }
                            }
                            
                        }
                    }];

                }
            }];
        }];
        [self registerAPI];
    }
    return self;
}

+ (instancetype)instance
{
    static DDGroupModule* group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        group = [[DDGroupModule alloc] init];
        
    });
    return group;
}
-(void)getGroupFromDB
{
    
}
-(void)addGroup:(GroupEntity*)newGroup
{
    if (!newGroup)
    {
        return;
    }
    GroupEntity* group = newGroup;
    [_allGroups setObject:group forKey:group.objID];
    newGroup = nil;
}
-(NSArray*)getAllGroups
{
    return [_allGroups allValues];
}
-(GroupEntity*)getGroupByGId:(NSString*)gId
{
    
    GroupEntity *entity= [_allGroups safeObjectForKey:gId];
  
    return entity;
}

- (void)getGroupInfogroupID:(NSString*)groupID completion:(GetGroupInfoCompletion)completion
{
    GroupEntity *group = [self getGroupByGId:groupID];
    if (group) {
        completion(group);
    }else{
        GetGroupInfoAPI* request = [[GetGroupInfoAPI alloc] init];
        [request requestWithObject:@[@([TheRuntime changeIDToOriginal:groupID]),@(group.objectVersion)] Completion:^(id response, NSError *error) {
            if (!error)
            {
                if ([response count]) {
                    GroupEntity* group = (GroupEntity*)response[0];
                    if (group)
                    {
                        [self addGroup:group];
                        [[DDDatabaseUtil instance] updateRecentGroup:group completion:^(NSError *error) {
                            DDLog(@"insert group to database error.");
                        }];
                    }
                    completion(group);
                }
                
            }
        }];
    }
    
}

-(BOOL)isContainGroup:(NSString*)gId
{
    return ([_allGroups valueForKey:gId] != nil);
}

- (void)registerAPI
{
    
    DDReceiveGroupAddMemberAPI* addmemberAPI = [[DDReceiveGroupAddMemberAPI alloc] init];
    [addmemberAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        if (!error)
        {
            
            GroupEntity* groupEntity = (GroupEntity*)object;
            if (!groupEntity)
            {
                return;
            }
            if ([self getGroupByGId:groupEntity.objID])
            {
                //自己本身就在组中
                
            }
            else
            {
                //自己被添加进组中
                
                groupEntity.lastUpdateTime = [[NSDate date] timeIntervalSince1970];
                [[DDGroupModule instance] addGroup:groupEntity];
//                [self addGroup:groupEntity];
//                DDSessionModule* sessionModule = getDDSessionModule();
//                [sessionModule createGroupSession:groupEntity.groupId type:GROUP_TYPE_TEMPORARY];
                [[NSNotificationCenter defaultCenter] postNotificationName:DDNotificationRecentContactsUpdate object:nil];
            }
        }
        else
        {
            DDLog(@"error:%@",[error domain]);
        }
    }];
    
//    DDReceiveGroupDeleteMemberAPI* deleteMemberAPI = [[DDReceiveGroupDeleteMemberAPI alloc] init];
//    [deleteMemberAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
//        if (!error)
//        {
//            GroupEntity* groupEntity = (GroupEntity*)object;
//            if (!groupEntity)
//            {
//                return;
//            }
//            DDUserlistModule* userModule = getDDUserlistModule();
//            if ([groupEntity.groupUserIds containsObject:userModule.myUserId])
//            {
//                //别人被踢了
//                [[DDMainWindowController instance] updateCurrentChattingViewController];
//            }
//            else
//            {
//                //自己被踢了
//                [self.recentlyGroupIds removeObject:groupEntity.groupId];
//                DDSessionModule* sessionModule = getDDSessionModule();
//                [sessionModule.recentlySessionIds removeObject:groupEntity.groupId];
//                DDMessageModule* messageModule = getDDMessageModule();
//                [messageModule popArrayMessage:groupEntity.groupId];
//                [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
//            }
//        }
//    }];
}


@end
