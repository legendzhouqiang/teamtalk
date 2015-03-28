//
//  DDChattingModule.h
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-28.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionEntity.h"
#import "DDUserEntity.h"
#define DD_PAGE_ITEM_COUNT                  20

typedef void(^DDReuestServiceCompletion)(DDUserEntity* user);
typedef void(^DDRequestGoodDetailCompletion)(NSDictionary* detail,NSError* error);
@class DDCommodity;
@class DDMessageEntity;
typedef void(^DDChatLoadMoreHistoryCompletion)(NSUInteger addcount, NSError* error);

@interface ChattingModule : NSObject
@property (strong)SessionEntity* sessionEntity;
@property(strong)NSMutableArray *ids ;
@property (strong)NSMutableArray* showingMessages;
@property (assign) NSInteger isGroup;
/**
 *  加载历史消息接口，这里会适时插入时间
 *
 *  @param completion 加载完成
 */
- (void)loadMoreHistoryCompletion:(DDChatLoadMoreHistoryCompletion)completion;

- (void)loadHostoryUntilCommodity:(DDMessageEntity*)message completion:(DDChatLoadMoreHistoryCompletion)completion;

- (float)messageHeight:(DDMessageEntity*)message;

- (void)addShowMessage:(DDMessageEntity*)message;
- (void)addShowMessages:(NSArray*)messages;
-(void)scanDBAndFixIDList:(void(^)(bool isok))block;
- (void)updateSessionUpdateTime:(NSUInteger)time;
- (void)clearChatData;
-(void)m_clearScanRecord;
- (void)showMessagesAddCommodity:(DDMessageEntity*)message;
-(void)getCurrentUser:(void(^)(DDUserEntity *))block;
-(void)loadHisToryMessageFromServer:(NSUInteger)FromMsgID loadCount:(NSUInteger)count Completion:(DDChatLoadMoreHistoryCompletion)completion;
-(void)loadHostoryMessageFromServer:(NSUInteger)FromMsgID Completion:(DDChatLoadMoreHistoryCompletion)completion;
+ (NSArray*)p_spliteMessage:(DDMessageEntity*)message;
-(void)getNewMsg:(DDChatLoadMoreHistoryCompletion)completion;
@end


@interface DDPromptEntity : NSObject
@property(nonatomic,retain)NSString* message;

@end