#import "GroupEntity.h"
#import "DDUserEntity.h"
#import "NSDictionary+Safe.h"
#import "DDDatabaseUtil.h"
@implementation GroupEntity

- (void)setGroupUserIds:(NSMutableArray *)groupUserIds
{
    if (_groupUserIds)
    {
        _groupUserIds = nil;
        _fixGroupUserIds = nil;
    }
    _groupUserIds = groupUserIds;
    [groupUserIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self addFixOrderGroupUserIDS:obj];
    }];
}

-(void)copyContent:(GroupEntity*)entity
{
    self.groupType = entity.groupType;
    self.lastUpdateTime = entity.lastUpdateTime;
    self.name = entity.name;
    self.avatar = entity.avatar;
    self.groupUserIds = entity.groupUserIds;
}

+(NSString *)getSessionId:(NSString *)groupId
{
     return groupId;
}
+(NSString *)pbGroupIdToLocalID:(UInt32)groupID
{
    return [NSString stringWithFormat:@"%@%ld",GROUP_PRE,groupID];
}
+(UInt32)localGroupIDTopb:(NSString *)groupID
{
    if (![groupID hasPrefix:GROUP_PRE]) {
        return 0;
    }
    return [[groupID substringFromIndex:[GROUP_PRE length]] integerValue];
}
+(GroupEntity *)initGroupEntityFromPBData:(GroupInfo *)groupInfo
{
    GroupEntity *group = [GroupEntity new];
    group.objID=[self pbGroupIdToLocalID:groupInfo.groupId];
    group.objectVersion=groupInfo.version;
    group.name=groupInfo.groupName;
    group.avatar = groupInfo.groupAvatar;
    group.groupCreatorId = [TheRuntime changeOriginalToLocalID:groupInfo.groupCreatorId SessionType:SessionTypeSessionTypeSingle];
    group.groupType = groupInfo.groupType;
    group.isShield=groupInfo.shieldStatus;
    NSMutableArray *ids  = [NSMutableArray new];
    for (int i = 0; i<[groupInfo.groupMemberList count]; i++) {
        [ids addObject:[TheRuntime changeOriginalToLocalID:[groupInfo.groupMemberList[i] integerValue] SessionType:SessionTypeSessionTypeSingle]];
    }
    group.groupUserIds = ids;
    group.lastMsg=@"";
    return group;
}
- (void)addFixOrderGroupUserIDS:(NSString*)ID
{
    if (!_fixGroupUserIds)
    {
        _fixGroupUserIds = [[NSMutableArray alloc] init];
    }
    [_fixGroupUserIds addObject:ID];
}

+(GroupEntity *)dicToGroupEntity:(NSDictionary *)dic
{
    GroupEntity *group = [GroupEntity new];
    group.groupCreatorId=[dic safeObjectForKey:@"creatID"];
    group.objID = [dic safeObjectForKey:@"groupId"];
    group.avatar = [dic safeObjectForKey:@"avatar"];
    group.GroupType = [[dic safeObjectForKey:@"groupType"] integerValue];
    group.name = [dic safeObjectForKey:@"name"];
    group.avatar = [dic safeObjectForKey:@"avatar"];
    group.isShield = [[dic safeObjectForKey:@"isshield"] boolValue];
    NSString *string =[dic safeObjectForKey:@"Users"];
    NSMutableArray *array =[NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"-"]] ;
    if ([array count] >0) {
        group.groupUserIds=[array copy];
    }
    group.lastMsg =[dic safeObjectForKey:@"lastMessage"];
    group.objectVersion = [[dic safeObjectForKey:@"version"] integerValue];
    group.lastUpdateTime=[[dic safeObjectForKey:@"lastUpdateTime"] longValue];
    return group;
}
-(BOOL)theVersionIsChanged
{
    return YES;
}
-(void)updateGroupInfo
{
    
}
@end
