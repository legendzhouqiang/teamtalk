//
//  DDDeleteMemberFromGroupAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-8.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDDeleteMemberFromGroupAPI.h"
#import "GroupEntity.h"
#import "DDGroupModule.h"
#import "IMGroup.pb.h"
@implementation DDDeleteMemberFromGroupAPI
/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return TimeOutTimeInterval;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return SERVICE_GROUP;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return SERVICE_GROUP;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_ID_GROUP_CHANGE_GROUP_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_ID_GROUP_CHANGE_GROUP_RES;
}

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData* data)
    {
        
        IMGroupChangeMemberRsp *rsp = [IMGroupChangeMemberRsp parseFromData:data];

        uint32_t result =rsp.resultCode;
        GroupEntity *groupEntity = nil;
        if (result != 0)
        {
            return groupEntity;
        }
        NSString *groupId =[GroupEntity pbGroupIdToLocalID:rsp.groupId];
        //NSArray *currentUserIds = rsp.curUserIdList;

        groupEntity =  [[DDGroupModule instance] getGroupByGId:groupId];
        NSMutableArray *array = [NSMutableArray new];
        for (uint32_t i = 0; i < [rsp.curUserIdList count]; i++) {
            NSString* userId = [TheRuntime changeOriginalToLocalID:[rsp.curUserIdList[i] integerValue] SessionType:SessionTypeSessionTypeSingle];
            [array addObject:userId];
        }
        groupEntity.groupUserIds=array;
        return groupEntity;
        
    };
    return analysis;
}

/**
 *  打包数据的block
 *
 *  @return 打包数据的block
 */
- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint16_t seqNo)
    {
        NSArray* array = (NSArray*)object;
        NSString* groupId = array[0];
        NSUInteger userid = [TheRuntime changeIDToOriginal:array[1]];
        IMGroupChangeMemberReqBuilder *memberChange = [IMGroupChangeMemberReq builder];
        [memberChange setUserId:[TheRuntime changeIDToOriginal:TheRuntime.user.objID]];
        [memberChange setChangeType:GroupModifyTypeGroupModifyTypeDel];
        [memberChange setGroupId:[TheRuntime changeIDToOriginal:groupId]];
        [memberChange setMemberIdListArray:@[@(userid)]];
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        [dataout writeInt:0];
        [dataout writeTcpProtocolHeader:SERVICE_GROUP cId:CMD_ID_GROUP_CHANGE_GROUP_REQ seqNo:seqNo];
        [dataout directWriteBytes:[memberChange build].data];
        [dataout writeDataCount];
        return [dataout toByteArray];
    };
    return package;
}
@end
