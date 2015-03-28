//
//  MsgReadNotify.m
//  TeamTalk
//
//  Created by Michael Scofield on 2014-12-19.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "MsgReadNotify.h"
#import "IMMessage.pb.h"
@implementation MsgReadNotify
- (int)responseServiceID
{
    return DDSERVICE_MESSAGE;
}

- (int)responseCommandID
{
    return MSG_MSG_READ_NOTIFY;
}

- (UnrequestAPIAnalysis)unrequestAnalysis
{
    UnrequestAPIAnalysis analysis = (id)^(NSData *data)
    {
        IMMsgDataReadNotify *notify = [IMMsgDataReadNotify parseFromData:data];
        NSMutableDictionary *dic = [NSMutableDictionary new];
        UInt32   sessionType =notify.sessionType;
        NSString *from_id = [TheRuntime changeOriginalToLocalID:notify.sessionId SessionType:sessionType];
        UInt32   msgId    = notify.msgId;
        [dic setObject:from_id forKey:@"from_id"];
        [dic setObject:@(msgId) forKey:@"msgId"];
        [dic setObject:@(sessionType) forKey:@"type"];
        return dic;
    };
    return analysis;
}
@end
