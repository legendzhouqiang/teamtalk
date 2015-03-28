//
//  GetRecentSession.m
//  TeamTalk
//
//  Created by Michael Scofield on 2014-12-03.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "GetRecentSession.h"
#import "SessionEntity.h"
#import "IMBuddy.pb.h"
#import "RuntimeStatus.h"
#import "GroupEntity.h"
#import "security.h"
@implementation GetRecentSession
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
    return RECENT_SESSION_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return RECENT_SESSION_RES;
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
        IMRecentContactSessionRsp *rsp =[IMRecentContactSessionRsp parseFromData:data];
        NSMutableArray *array = [NSMutableArray new];
        
        for (ContactSessionInfo *sessionInfo in rsp.contactSessionList) {
            NSString *sessionId =@"";
            SessionType sessionType =sessionInfo.sessionType;
            if (sessionType == SessionTypeSessionTypeSingle) {
                sessionId = [DDUserEntity pbUserIdToLocalID:sessionInfo.sessionId];
            }else{
                sessionId = [GroupEntity pbGroupIdToLocalID:sessionInfo.sessionId];
            }
            NSInteger updated_time = sessionInfo.updatedTime;
            SessionEntity *session =[[SessionEntity alloc] initWithSessionID:sessionId type:sessionType];
            
            NSString *string =[[NSString alloc] initWithData:sessionInfo.latestMsgData encoding:NSUTF8StringEncoding];

            char* pOut;
            uint32_t nOutLen;
            uint32_t nInLen = strlen([string cStringUsingEncoding:NSUTF8StringEncoding]);
             int nRet =  DecryptMsg([string cStringUsingEncoding:NSUTF8StringEncoding], nInLen, &pOut, nOutLen);
            if (nRet == 0) {
                session.lastMsg=[NSString stringWithCString:pOut encoding:NSUTF8StringEncoding];
                Free(pOut);
            }else{
                session.lastMsg=@" ";
            }
          
            session.lastMsgID=sessionInfo.latestMsgId;
            session.timeInterval=updated_time;
            [array addObject:session];

        }
        return array;
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
        IMRecentContactSessionReqBuilder *req = [IMRecentContactSessionReq builder];
        [req setUserId:0];
        [req setLatestUpdateTime:[object[0] integerValue]];
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        [dataout writeInt:0];
        [dataout writeTcpProtocolHeader:MODULE_ID_SESSION
                                    cId:RECENT_SESSION_REQ
                                  seqNo:seqNo];
        [dataout directWriteBytes:[req build].data];
        [dataout writeDataCount];
        return [dataout toByteArray];
    };
    return package;
}
@end
