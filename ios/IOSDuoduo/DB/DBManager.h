//
//  DBManager.h
//  TeamTalk
//
//  Created by Michael Scofield on 2014-12-24.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBHelper.h"
#import "DDUserEntity.h"
#import "std.h"
enum{
    User_DB,
    MessageDB,
    SessionDB,
    GroupDB
    
} TeamTalkDBType;
@interface DBManager : NSObject
AS_SINGLETON(DBManager)
-(void)updateUser:(DDUserEntity *)user;
-(void)insertUsers:(NSArray *)array;
-(NSMutableArray *)getAllUser;
-(void)setUsersVersion:(NSUInteger)version;
-(NSInteger)getUsersVersion;
@end
