//
//  DBManager.m
//  TeamTalk
//
//  Created by Michael Scofield on 2014-12-24.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "DBManager.h"
#import "NSString+Additions.h"
#import "DDUserEntity.h"
#import "std.h"
@interface DBManager()
@property(strong)DBHelper *userDB;
@property(strong)DBHelper *ttdb;
@end
@implementation DBManager
DEF_SINGLETON(DBManager)
- (instancetype)init
{
    self = [super init];
    if (self) {
        BOOL isExist = ![[NSFileManager defaultManager] fileExistsAtPath:[self dbPath]];
        if (isExist) {
              self.userDB = [[DBHelper alloc] initWithPath:[self userDBPath]];
            self.ttdb = [[DBHelper alloc] initWithPath:[self dbPath]];
        }
    }
    return self;
}
-(NSString*) dbPath{
    return [[NSString documentPath] stringByAppendingPathComponent:@"teamtalk_db"];
}
-(NSString *) userDBPath
{
    return [[NSString documentPath] stringByAppendingPathComponent:@"teamtalk_user_db"];
}
#pragma mark - User Operation
-(NSMutableArray *)getAllUser
{
    __block NSMutableArray *users = [NSMutableArray new];
    [self.userDB enumerateKeys:^(NSString *key, BOOL *stop) {
        DDUserEntity *user = [self getUserByID:key];
        [users addObject:user];
    }];
   return  users;

}
-(void)insertUser:(DDUserEntity *)user
{
    NSDictionary *dic = [DDUserEntity userToDic:user];
    [self.userDB setObject:dic forKey:user.objID];
}
-(void)insertUsers:(NSArray *)array
{
    [array enumerateObjectsUsingBlock:^(DDUserEntity *obj, NSUInteger idx, BOOL *stop) {
        [self insertUser:obj];
    }];
}
-(void)updateUser:(DDUserEntity *)user
{
    [self removeUser:user];
    [self insertUser:user];
}
-(void)removeUser:(DDUserEntity *)user
{
    [self removeUserByID:user.objID];
}
-(void)removeUserByID:(NSString *)userID
{
    [self.userDB removeValueForKey:userID];
}
-(DDUserEntity *)getUserByID:(NSString *)userID
{
    return [self.userDB objectForKey:userID];
}
-(BOOL)userVersionIsChanged:(NSString *)userID Version:(NSUInteger)version
{
    DDUserEntity *user = [self getUserByID:userID];
    if (user.objectVersion == version) {
        return NO;
    }
    return YES;
}
-(void)setUsersVersion:(NSUInteger)version
{
    [self.ttdb setInt:version forKey:@"usersversion"];
}
-(NSInteger)getUsersVersion
{
    return  [self.ttdb intForKey:@"usersversion"];
}
@end
