//
//  DDMessageSendManager.h
//  Duoduo
//
//  Created by 独嘉 on 14-3-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDMessageEntity.h"
@class SessionEntity;
typedef void(^DDSendMessageCompletion)(DDMessageEntity* message,NSError* error);

typedef NS_ENUM(NSUInteger, MessageType)
{
    AllString,
    HasImage
};

@class DDMessageEntity;
@interface DDMessageSendManager : NSObject
@property (nonatomic,readonly)dispatch_queue_t sendMessageSendQueue;
@property (nonatomic,readonly)NSMutableArray* waitToSendMessage;
+ (instancetype)instance;

/**
 *  发送消息
 *
 *  @param content 发送内容，是富文本
 *  @param session 所属的会话
 */
//- (void)sendMessage:(NSAttributedString*)content forSession:(SessionEntity*)session success:(void(^)(NSString* sendedContent))success  failure:(void(^)(NSString*))failure;


/**
 *  发送消息
 *
 *  @param content    消息内容
 *  @param sessionID  会话ID
 *  @param completion 完成发送消息
 */
- (void)sendMessage:(DDMessageEntity *)message isGroup:(BOOL)isGroup Session:(SessionEntity*)session completion:(DDSendMessageCompletion)completion Error:(void(^)(NSError *error))block;


- (void)sendVoiceMessage:(NSData*)voice filePath:(NSString*)filePath forSessionID:(NSString*)sessionID isGroup:(BOOL)isGroup Message:(DDMessageEntity *)msg Session:(SessionEntity*)session completion:(DDSendMessageCompletion)completion;
@end