//
//  DDLoginAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-6.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "LoginAPI.h"
#import "DDUserEntity.h"
#import "IMLogin.pb.h"
#import "IMBaseDefine.pb.h"
#import "DDUserEntity.h"
#import "NSString+Additions.h"
#import "security.h"
@implementation LoginAPI
/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 15;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return DDSERVICE_LOGIN;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return DDSERVICE_LOGIN;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return DDCMD_LOGIN_REQ_USERLOGIN;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return DDCMD_LOGIN_RES_USERLOGIN;
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
        IMLoginRes *res = [IMLoginRes parseFromData:data];
        NSInteger serverTime = res.serverTime;
        NSInteger loginResult = res.resultCode;
        NSString *resultString=nil;
        resultString = res.resultString;
        NSDictionary* result = nil;
        if (loginResult !=0) {
            return result;
        }else
        {
            DDUserEntity *user = [[DDUserEntity alloc] initWithPB:res.userInfo];
            result = @{@"serverTime":@(serverTime),
                                     @"result":resultString,
                                     @"user":user,
                                     };
            return result;
        }
        
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
    Package package = (id)^(id object,uint32_t seqNo)
    {

        NSString *clientVersion = [NSString stringWithFormat:@"MAC/%@-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        NSString * strMsg = object[1];
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        [dataout writeInt:0];
        [dataout writeTcpProtocolHeader:DDSERVICE_LOGIN
                                    cId:DDCMD_LOGIN_REQ_USERLOGIN
                                  seqNo:seqNo];

        IMLoginReqBuilder *login = [IMLoginReq builder];
        [login setUserName:object[0]];
        [login setPassword:[strMsg MD5]];
        [login setClientType:ClientTypeClientTypeIos];
        [login setClientVersion:clientVersion];
        [login setOnlineStatus:UserStatTypeUserStatusOnline];
        [dataout directWriteBytes:[login build].data];
        [dataout writeDataCount];
        return [dataout toByteArray];
    };
    return package;
}
@end
