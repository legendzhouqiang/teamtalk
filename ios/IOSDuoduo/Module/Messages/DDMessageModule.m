//
//  DDMessageModule.m
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-27.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "DDMessageModule.h"
#import "DDDatabaseUtil.h"
#import "DDReceiveMessageAPI.h"
#import "GetUnreadMessagesAPI.h"
#import "DDAFClient.h"
#import "SessionEntity.h"
#import "RuntimeStatus.h"
#import "MsgReadACKAPI.h"
#import "DDUserModule.h"
#import "DDReceiveMessageACKAPI.h"
#import "AnalysisImage.h"
#import "RecentUsersViewController.h"
#import "GetMessageQueueAPI.h"
#import "DDGroupModule.h"
#import "MsgReadNotify.h"
@interface DDMessageModule(PrivateAPI)
- (void)p_registerReceiveMessageAPI;
- (void)p_saveReceivedMessage:(DDMessageEntity*)message;
- (void)n_receiveLoginSuccessNotification:(NSNotification*)notification;
- (void)n_receiveUserLogoutNotification:(NSNotification*)notification;
- (NSArray*)p_spliteMessage:(DDMessageEntity*)message;
@end

@implementation DDMessageModule
{
    NSMutableDictionary* _unreadMessages;
}
+ (instancetype)shareInstance
{
    static DDMessageModule* g_messageModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_messageModule = [[DDMessageModule alloc] init];
    });
    return g_messageModule;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        //注册收到消息API
        self.unreadMsgCount =0;
        _unreadMessages = [[NSMutableDictionary alloc] init];
        [self p_registerReceiveMessageAPI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveLoginSuccessNotification:) name:DDNotificationUserLoginSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveLoginSuccessNotification:) name:DDNotificationUserReloginSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveUserLogoutNotification:) name:DDNotificationLogout object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSUInteger )getMessageID
{
    NSInteger messageID = [[NSUserDefaults standardUserDefaults] integerForKey:@"msg_id"];
    if(messageID == 0)
    {
        messageID=LOCAL_MSG_BEGIN_ID;
    }else{
        messageID ++;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:messageID forKey:@"msg_id"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return messageID;
}

- ( void)getLastMessageForSessionID:(NSString*)sessionID block:(GetLastestMessageCompletion)block {
    
    [[DDDatabaseUtil instance] getLastestMessageForSessionID:sessionID completion:^(DDMessageEntity *message, NSError *error) {
            block(message);
        }];
    
    
}

- (void)addUnreadMessage:(DDMessageEntity*)message
{
    @synchronized(self) {
        if (!message)
        {
            return;
        }
        if([message.sessionId isEqualToString:@"1szei2"])
        {
            return;
        }
        
        //senderId 即 sessionId
        if (![message isGroupMessage]) {
            if ([[_unreadMessages allKeys] containsObject:message.sessionId])
            {
                NSMutableArray* unreadMessage = _unreadMessages[message.sessionId];
                [unreadMessage addObject:message];
            }
            else
            {
                NSMutableArray* unreadMessages = [[NSMutableArray alloc] init];
                [unreadMessages addObject:message];
                [_unreadMessages setObject:unreadMessages forKey:message.sessionId];
            }
        }else
        {
            if ([[_unreadMessages allKeys] containsObject:message.sessionId])
            {
                NSMutableArray* unreadMessage = _unreadMessages[message.sessionId];
                [unreadMessage addObject:message];
            }
            else
            {
                NSMutableArray* unreadMessages = [[NSMutableArray alloc] init];
                [unreadMessages addObject:message];
                [_unreadMessages setObject:unreadMessages forKey:message.sessionId];
            }
        }
    }
    
}
-(void)sendMsgRead:(DDMessageEntity *)message
{
    MsgReadACKAPI* readACK = [[MsgReadACKAPI alloc] init];
    [readACK requestWithObject:@[message.sessionId,@(message.msgID),@(message.sessionType)] Completion:nil];
}
- (void)clearUnreadMessagesForSessionID:(NSString*)sessionID
{
    
   


    NSMutableArray* unreadMessages = _unreadMessages[sessionID];
    if (unreadMessages)
    {
        [unreadMessages enumerateObjectsUsingBlock:^(DDMessageEntity* messageEntity, NSUInteger idx, BOOL *stop) {
            [[DDDatabaseUtil instance]insertMessages:@[messageEntity] success:^{
            MsgReadACKAPI* readACK = [[MsgReadACKAPI alloc] init];
            [readACK requestWithObject:@[messageEntity.sessionId,@(messageEntity.msgID),@(messageEntity.msgType)] Completion:nil];
                
            } failure:^(NSString *errorDescripe) {
                NSLog(@"消息插入DB失败");
            }];
        }];
        
        
    }
    [unreadMessages removeAllObjects];
    [self setApplicationUnreadMsgCount];
}

- (NSUInteger)getUnreadMessageCountForSessionID:(NSString*)sessionID
{
    if ([sessionID isEqualToString:TheRuntime.userID]) {
        return 0;
    }
    
    NSMutableArray* unreadMessages = _unreadMessages[sessionID];
    return [unreadMessages count];
}
-(NSArray *)getUnreadMessageBySessionID:(NSString *)sessionID
{
    return _unreadMessages[sessionID];
}

- (NSUInteger)getUnreadMessgeCount
{
    __block NSUInteger count = 0;
    [_unreadMessages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        count += [obj count];
    }];
    
    return count;
}
-(void)removeFromUnreadMessageButNotSendRead:(NSString*)sessionID
{
    
    NSMutableArray* messages = _unreadMessages[sessionID];
    DDLog(@" remove message %d--->,%@ id is ",[messages count],sessionID);
    if ([messages count]> 0)
    {
        [_unreadMessages removeObjectForKey:sessionID];
    }
    
}
- (NSArray*)popAllUnreadMessagesForSessionID:(NSString*)sessionID
{
    NSMutableArray* messages = _unreadMessages[sessionID];
    if ([messages count]> 0)
    {
        [[DDDatabaseUtil instance] insertMessages:messages success:^{
            DDMessageEntity* message = messages[0];
            SessionType sessionType = [message getMessageSessionType];
            MsgReadACKAPI* readACK = [[MsgReadACKAPI alloc] init];
            [readACK requestWithObject:@[message.sessionId,@(message.msgID),@(sessionType)] Completion:nil];
          
        } failure:^(NSString *errorDescripe) {
            NSLog(@"消息插入DB失败");
            
        }];
        [_unreadMessages removeObjectForKey:sessionID];
        return messages;
    }
    else
    {
        return nil;
    }
}

#pragma mark - privateAPI
- (void)p_registerReceiveMessageAPI
{
    DDReceiveMessageAPI* receiveMessageAPI = [[DDReceiveMessageAPI alloc] init];
    [receiveMessageAPI registerAPIInAPIScheduleReceiveData:^(DDMessageEntity* object, NSError *error) {
        object.state=DDmessageSendSuccess;
        DDReceiveMessageACKAPI *rmack = [[DDReceiveMessageACKAPI alloc] init];
        [rmack requestWithObject:@[object.senderId,@(object.msgID),object.sessionId,@(object.sessionType)] Completion:^(id response, NSError *error) {
            
        }];
        NSArray* messages = [self p_spliteMessage:object];
//        [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            [self p_saveReceivedMessage:obj];
//        }];
        if ([object isGroupMessage]) {
            GroupEntity *group = [[DDGroupModule instance] getGroupByGId:object.sessionId];
            if (group.isShield == 1) {
                MsgReadACKAPI* readACK = [[MsgReadACKAPI alloc] init];
                [readACK requestWithObject:@[object.sessionId,@(object.msgID),@(object.sessionType)] Completion:nil];
            }
        }
        [[DDDatabaseUtil instance] insertMessages:@[object] success:^{
            
        } failure:^(NSString *errorDescripe) {
            
        }];
        [DDNotificationHelp postNotification:DDNotificationReceiveMessage userInfo:nil object:object];
    }];
    
    //消息已读通知
//    MsgReadNotify *msgReadNotify = [MsgReadNotify new];
//    [msgReadNotify requestWithObject:nil Completion:^(NSDictionary *object, NSError *error) {
//        NSString *fromId= [object objectForKey:@"from_id"];
//        UInt32 msgID = [[object objectForKey:@"msgId"] integerValue];
//        UInt32 sessionType = [[object objectForKey:@"sessionType"] integerValue];
//        [self cleanMessageFromNotifi:msgID SessionID:fromId SessionType:sessionType];
//    }];
  
   
}

- (void)p_saveReceivedMessage:(DDMessageEntity*)messageEntity
{


    SessionEntity* session = [[SessionEntity alloc] initWithSessionID:messageEntity.sessionId type:messageEntity.sessionType];
    [session updateUpdateTime:messageEntity.msgTime];
    if (messageEntity)
    {
        messageEntity.state=DDmessageSendSuccess;
        [self addUnreadMessage:messageEntity];
        
        [DDNotificationHelp postNotification:DDNotificationReceiveMessage userInfo:nil object:messageEntity];
    }
}

-(void)getMessageFromServer:(NSInteger)fromMsgID currentSession:(SessionEntity *)session count:(NSInteger)count Block:(void(^)(NSMutableArray *array, NSError *error))block
{
    GetMessageQueueAPI *getMessageQueue = [GetMessageQueueAPI new];
    [getMessageQueue requestWithObject:@[@(fromMsgID),@(count),@(session.sessionType),session.sessionID] Completion:^(NSMutableArray *response, NSError *error) {
        block(response,error);
        
    }];
    
}


- (void)n_receiveLoginSuccessNotification:(NSNotification*)notification
{
    //_unreadMessages = [[NSMutableDictionary alloc] init];
}
-(void)removeArrayMessage:(NSString*)sessionId
{
    if(!sessionId)
        return;
    [_unreadMessages removeObjectForKey:sessionId];
    [self setApplicationUnreadMsgCount];
}

- (void)n_receiveUserLogoutNotification:(NSNotification*)notification
{
    [_unreadMessages removeAllObjects];
}

- (NSArray*)p_spliteMessage:(DDMessageEntity*)message
{
    NSMutableArray* messageContentArray = [[NSMutableArray alloc] init];
    if (message.msgContentType == DDMessageTypeImage || (message.msgContentType == DDMessageTypeText && [message.msgContent rangeOfString:DD_MESSAGE_IMAGE_PREFIX].length > 0))
    {
        NSString* messageContent = [message msgContent];
        NSArray* tempMessageContent = [messageContent componentsSeparatedByString:DD_MESSAGE_IMAGE_PREFIX];
        [tempMessageContent enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* content = (NSString*)obj;
            if ([content length] > 0)
            {
                NSRange suffixRange = [content rangeOfString:DD_MESSAGE_IMAGE_SUFFIX];
                if (suffixRange.length > 0)
                {
                    //是图片,再拆分
                    NSString* imageContent = [NSString stringWithFormat:@"%@%@",DD_MESSAGE_IMAGE_PREFIX,[content substringToIndex:suffixRange.location + suffixRange.length]];
                    DDMessageEntity* messageEntity = [[DDMessageEntity alloc] initWithMsgID:[DDMessageModule getMessageID] msgType:message.msgType msgTime:message.msgTime sessionID:message.sessionId senderID:message.senderId msgContent:imageContent toUserID:message.toUserID];
                    messageEntity.msgContentType = DDMessageTypeImage;
                    messageEntity.state = DDmessageSendSuccess;
                    [messageContentArray addObject:messageEntity];
                    
                    
                    NSString* secondComponent = [content substringFromIndex:suffixRange.location + suffixRange.length];
                    if (secondComponent.length > 0)
                    {
                        DDMessageEntity* secondmessageEntity = [[DDMessageEntity alloc] initWithMsgID:[DDMessageModule getMessageID] msgType:message.msgType msgTime:message.msgTime sessionID:message.sessionId senderID:message.senderId msgContent:secondComponent toUserID:message.toUserID];
                        secondmessageEntity.msgContentType = DDMessageTypeText;
                        secondmessageEntity.state = DDmessageSendSuccess;
                        [messageContentArray addObject:secondmessageEntity];
                    }
                }
                else
                {
           
                    DDMessageEntity* messageEntity = [[DDMessageEntity alloc] initWithMsgID:[DDMessageModule getMessageID] msgType:message.msgType msgTime:message.msgTime sessionID:message.sessionId senderID:message.senderId msgContent:content toUserID:message.toUserID];
                    messageEntity.msgContentType = DDMessageTypeText;
                    messageEntity.state = DDmessageSendSuccess;
                    [messageContentArray addObject:messageEntity];
                }
            }
        }];
    }
    if ([messageContentArray count] == 0)
    {
        [messageContentArray addObject:message];
    }
    return messageContentArray;
}

-(void)setApplicationUnreadMsgCount
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self getUnreadMessgeCount]];
}
-(NSUInteger)getUnreadCountById:(NSString *)sessionID
{
    return 0;
}

-(void)cleanMessageFromNotifi:(NSUInteger)messageID  SessionID:(NSString *)sessionid SessionType:(SessionType )sessionType
{
//     NSMutableArray * messages = _unreadMessages[sessionid];
//    [messages enumerateObjectsUsingBlock:^(DDMessageEntity * obj, NSUInteger idx, BOOL *stop) {
//          if (obj.msgID < messageID)
//          {
//              [[DDDatabaseUtil instance] insertMessages:@[obj] success:^{
//                SessionType sessionType =[obj getMessageSessionType];
//                MsgReadACKAPI* readACK = [[MsgReadACKAPI alloc] init];
//                [readACK requestWithObject:@[obj.sessionId,@(obj.msgID),@(sessionType)] Completion:nil];
//                [messages removeObject:obj];
//                  [[NSNotificationCenter defaultCenter] postNotificationName:@"MessageReadACK" object:obj];
//              } failure:^(NSString *errorDescripe) {
//
//              }];
//
//          }
//    }];

}

@end
