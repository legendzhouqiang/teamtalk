//
//  SessionModule.h
//  TeamTalk
//
//  Created by Michael Scofield on 2014-12-05.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "std.h"
@class SessionEntity;
typedef enum
{
    ADD = 0,
    REFRESH = 1,
    DELETE =2
}SessionAction;
@protocol SessionModuelDelegate<NSObject>
@optional
- (void)sessionUpdate:(SessionEntity *)session Action:(SessionAction)action;
@end
@interface SessionModule : NSObject
AS_SINGLETON(SessionModule)
@property(strong)id<SessionModuelDelegate>delegate;
-(NSArray *)getAllSessions;
-(void)addToSessionModel:(SessionEntity *)session;
-(void)addSessionsToSessionModel:(NSArray *)sessionArray;
-(SessionEntity *)getSessionById:(NSString *)sessionID;
-(void)getRecentSession:(void(^)(NSUInteger count))block;
-(void)removeSessionByServer:(SessionEntity *)session;
-(void)loadLocalSession:(void(^)(bool isok))block;
-(void)getHadUnreadMessageSession:(void(^)(NSUInteger count))block;
-(NSUInteger)getAllUnreadMessageCount;
@end