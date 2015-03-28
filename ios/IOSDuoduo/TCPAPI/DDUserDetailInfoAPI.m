//
//  DDUserDetailInfoAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDUserDetailInfoAPI.h"
#import "IMBuddy.pb.h"
#import "RuntimeStatus.h"
#import "DDUserEntity.h"
@implementation DDUserDetailInfoAPI
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
    return MODULE_ID_FRIENDLIST;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_FRIENDLIST;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return 18;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return 19;
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
        IMUsersInfoRsp *rsp = [IMUsersInfoRsp parseFromData:data];
        NSMutableArray* userList = [[NSMutableArray alloc] init];
        for (UserInfo *userInfo in rsp.userInfoList) {
            DDUserEntity *user = [[DDUserEntity alloc] initWithPB:userInfo];
            [userList addObject:user];
        }
        return userList;
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
        NSArray* users = (NSArray*)object;
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        IMUsersInfoReqBuilder *userInfoReqBuiler = [IMUsersInfoReq builder];
        [userInfoReqBuiler setUserId:0];
        [userInfoReqBuiler setUserIdListArray:users];
        [dataout writeTcpProtocolHeader:MODULE_ID_FRIENDLIST
                                    cId:18
                                  seqNo:seqNo];
        [dataout writeBytes:[userInfoReqBuiler build].data];
     
        return [dataout toByteArray];
    };
    return package;
}
@end
