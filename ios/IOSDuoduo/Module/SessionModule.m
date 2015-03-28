//
//  SessionModule.m
//  TeamTalk
//
//  Created by Michael Scofield on 2014-12-05.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "SessionModule.h"
#import "SessionEntity.h"
#import "NSDictionary+Safe.h"
#import "GetUnreadMessagesAPI.h"
#import "RemoveSessionAPI.h"
#import "DDDatabaseUtil.h"
#import "GetRecentSession.h"
#import "DDMessageEntity.h"
#import "ChattingMainViewController.h"
#import "MsgReadNotify.h"
#import "MsgReadACKAPI.h"
#import "SpellLibrary.h"
#import "DDGroupModule.h"
@interface SessionModule()
@property(strong)NSMutableDictionary *sessions;
@end
@implementation SessionModule
DEF_SINGLETON(SessionModule)
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sessions = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sentMessageSuccessfull:) name:@"SentMessageSuccessfull" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getMessageReadACK:) name:@"MessageReadACK" object:nil];
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logout) name:DDNotificationLogout object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(n_receiveMessageNotification:)
                                                     name:DDNotificationReceiveMessage
                                                   object:nil];
        MsgReadNotify *msgReadNotify = [[MsgReadNotify alloc] init];
        [msgReadNotify registerAPIInAPIScheduleReceiveData:^(NSDictionary *object, NSError *error) {
            NSString *fromId= [object objectForKey:@"from_id"];
            NSInteger msgID = [[object objectForKey:@"msgId"] integerValue];
            SessionType type = [[object objectForKey:@"type"] intValue];
            [self cleanMessageFromNotifi:msgID SessionID:fromId Session:type];
        }];
    }
    return self;
}
-(SessionEntity *)getSessionById:(NSString *)sessionID
{
    return [self.sessions safeObjectForKey:sessionID];
}
-(void)removeSessionById:(NSString *)sessionID
{
    [self.sessions removeObjectForKey:sessionID];
}
-(void)addToSessionModel:(SessionEntity *)session
{
    [self.sessions safeSetObject:session forKey:session.sessionID];
}
-(NSUInteger)getAllUnreadMessageCount
{
    return [[[self getAllSessions] valueForKeyPath:@"@sum.unReadMsgCount"] integerValue];
}
-(void)addSessionsToSessionModel:(NSArray *)sessionArray
{
    [sessionArray enumerateObjectsUsingBlock:^(SessionEntity *session, NSUInteger idx, BOOL *stop) {
        [self.sessions safeSetObject:session forKey:session.sessionID];
    }];
}
-(void)getHadUnreadMessageSession:(void(^)(NSUInteger count))block
{
    GetUnreadMessagesAPI *getUnreadMessage = [GetUnreadMessagesAPI new];
    [getUnreadMessage requestWithObject:TheRuntime.user.objID Completion:^(NSDictionary *dic, NSError *error) {
        NSInteger m_total_cnt =[dic[@"m_total_cnt"] integerValue];
        NSArray *localsessions = dic[@"sessions"];
        [localsessions enumerateObjectsUsingBlock:^(SessionEntity *obj, NSUInteger idx, BOOL *stop){
         
            if ([self getSessionById:obj.sessionID]) {
                
                SessionEntity *session = [self getSessionById:obj.sessionID];
                NSInteger lostMsgCount =obj.lastMsgID-session.lastMsgID;
                obj.lastMsg = session.lastMsg;
                if ([[ChattingMainViewController shareInstance].module.sessionEntity.sessionID isEqualToString:obj.sessionID]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChattingSessionUpdate" object:@{@"session":obj,@"count":@(lostMsgCount)}];
                }
                session=obj;
                [self addToSessionModel:obj];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(sessionUpdate:Action:)]) {
                [self.delegate sessionUpdate:obj Action:ADD];
            }
            
           
        }];
        
        //[self addSessionsToSessionModel:sessions];
        block(m_total_cnt);
        //通知外层sessionmodel发生更新
    }];
}

-(NSUInteger )getMaxTime
{
    NSArray *array =[self getAllSessions];
    NSUInteger maxTime = [[array valueForKeyPath:@"@max.timeInterval"] integerValue];
    if (maxTime) {
        return maxTime;
    }
    return 0;
}
-(void)getRecentSession:(void(^)(NSUInteger count))block
{
    GetRecentSession *getRecentSession = [[GetRecentSession alloc] init];
    NSInteger localMaxTime = [self getMaxTime];
    [getRecentSession requestWithObject:@[@(localMaxTime)] Completion:^(NSArray *response, NSError *error) {
#pragma 测试代码
        NSMutableArray *array = [NSMutableArray arrayWithArray:response];
        [self addSessionsToSessionModel:array];
        response = array;
        [self getHadUnreadMessageSession:^(NSUInteger count) {
            
        }];
        [response enumerateObjectsUsingBlock:^(SessionEntity *obj, NSUInteger idx, BOOL *stop) {
            //同步到数据库中
            [[DDDatabaseUtil instance] updateRecentSession:obj completion:^(NSError *error) {
                        
                    }];
        }];
        block(0);

    }];
}

-(NSArray *)getAllSessions
{
    return [self.sessions allValues];
}
-(void)removeSessionByServer:(SessionEntity *)session
{
    [self.sessions removeObjectForKey:session.sessionID];
    [[DDDatabaseUtil instance] removeSession:session.sessionID];
    RemoveSessionAPI *removeSession = [RemoveSessionAPI new];
    SessionType sessionType = session.sessionType;
    [removeSession requestWithObject:@[session.sessionID,@(sessionType)] Completion:^(id response, NSError *error) {
       
    }];
}
-(void)getMessageReadACK:(NSNotification *)notification
{
      DDMessageEntity* message = [notification object];
    if ([[self.sessions allKeys] containsObject:message.sessionId]) {
        SessionEntity *session = [self.sessions objectForKey:message.sessionId];
        session.unReadMsgCount=session.unReadMsgCount-1;
        
    }
}
- (void)n_receiveMessageNotification:(NSNotification*)notification
{
    DDMessageEntity* message = [notification object];

    SessionType sessionType;
    SessionEntity *session;
    if ([message isGroupMessage]) {
        sessionType = SessionTypeSessionTypeGroup;
    } else{
        sessionType = SessionTypeSessionTypeSingle;
    }
   
    if ([[self.sessions allKeys] containsObject:message.sessionId]) {
         session = [self.sessions objectForKey:message.sessionId];
        session.lastMsg=message.msgContent;
        session.lastMsgID = message.msgID;
        session.timeInterval = message.msgTime;
        if (![message.sessionId isEqualToString:[ChattingMainViewController shareInstance].module.sessionEntity.sessionID]) {
            if (![message.senderId isEqualToString:TheRuntime.user.objID]) {
                    session.unReadMsgCount=session.unReadMsgCount+1;
            }
        }
        
    }else{
        session = [[SessionEntity alloc] initWithSessionID:message.sessionId type:sessionType];
        session.lastMsg=message.msgContent;
        session.lastMsgID = message.msgID;
        session.timeInterval = message.msgTime;
        if (![message.sessionId isEqualToString:[ChattingMainViewController shareInstance].module.sessionEntity.sessionID]) {
            if (![message.senderId isEqualToString:TheRuntime.user.objID]) {
                session.unReadMsgCount=session.unReadMsgCount+1;
            }
            
        }
        [self addSessionsToSessionModel:@[session]];
    }
    [self updateToDatabase:session];
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(sessionUpdate:Action:)]) {
        [self.delegate sessionUpdate:session Action:ADD];
    }
    
}
-(void)updateToDatabase:(SessionEntity *)session{
    [[DDDatabaseUtil instance] updateRecentSession:session completion:^(NSError *error) {
        
    }];
}
-(void)sentMessageSuccessfull:(NSNotification*)notification
{
    SessionEntity* session = [notification object];
    [self addSessionsToSessionModel:@[session]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(sessionUpdate:Action:)]) {
        [self.delegate sessionUpdate:session Action:ADD];
    }
     [self updateToDatabase:session];
}
-(void)loadLocalSession:(void(^)(bool isok))block
{
    [[DDDatabaseUtil instance] loadSessionsCompletion:^(NSArray *session, NSError *error) {
        
        [self addSessionsToSessionModel:session];
        block(YES);
        
    }];

}
-(void)cleanMessageFromNotifi:(NSUInteger)messageID  SessionID:(NSString *)sessionid Session:(SessionType)type
{
    if(![sessionid isEqualToString:TheRuntime.user.objID]){
        SessionEntity *session = [self getSessionById:sessionid];
        if (session) {
            NSInteger readCount =messageID-session.lastMsgID;
            if (readCount == 0) {
                session.unReadMsgCount =0;
                if (self.delegate && [self.delegate respondsToSelector:@selector(sessionUpdate:Action:)]) {
                    [self.delegate sessionUpdate:session Action:ADD];
                }
                [self updateToDatabase:session];
                
            }else if(readCount > 0){
                session.unReadMsgCount =readCount;
                if (self.delegate && [self.delegate respondsToSelector:@selector(sessionUpdate:Action:)]) {
                    [self.delegate sessionUpdate:session Action:ADD];
                }
                [self updateToDatabase:session];
            }
            MsgReadACKAPI* readACK = [[MsgReadACKAPI alloc] init];
            [readACK requestWithObject:@[sessionid,@(messageID),@(type)] Completion:nil];
        }
        
    }
}
-(void)logout
{
    [self.sessions removeAllObjects];
}
@end
