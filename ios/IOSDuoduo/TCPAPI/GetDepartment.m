//
//  GetDepartment.m
//  TeamTalk
//
//  Created by Michael Scofield on 2015-03-16.
//  Copyright (c) 2015 Michael Hu. All rights reserved.
//

#import "GetDepartment.h"
#import "IMBuddy.pb.h"
@implementation GetDepartment
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
    return MODULE_ID_SESSION;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_SESSION;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return DEPARTINFO_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return DEPARTINFO_RES;
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
        IMDepartmentRsp *rsp =[IMDepartmentRsp parseFromData:data];
        NSDictionary *dic = nil;
        if (rsp.deptList) {
            dic = @{@"allDeplastupdatetime":@(rsp.latestUpdateTime),@"deplist":rsp.deptList};
            return dic;
        }
        return dic;
        
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
        IMDepartmentReqBuilder *req = [IMDepartmentReq builder];
        [req setUserId:0];
        [req setLatestUpdateTime:[object[0] integerValue]];
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        [dataout writeInt:0];
        [dataout writeTcpProtocolHeader:MODULE_ID_SESSION
                                    cId:DEPARTINFO_REQ
                                  seqNo:seqNo];
        [dataout directWriteBytes:[req build].data];
        [dataout writeDataCount];
        return [dataout toByteArray];
    };
    return package;
}
@end
