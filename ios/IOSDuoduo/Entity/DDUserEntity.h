//
//  DDUserEntity.h
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-26.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDepartment.h"
#import "DDBaseEntity.h"
#import "IMBaseDefine.pb.h"
#define DD_USER_INFO_SHOP_ID_KEY                    @"shopID"

@interface DDUserEntity : DDBaseEntity
@property(nonatomic,strong) NSString *name;         //用户名
@property(nonatomic,strong) NSString *nick;         //用户昵称
@property(nonatomic,strong) NSString *avatar;       //用户头像
@property(nonatomic,strong) NSString *department;   //用户部门
@property(strong)NSString *position;
@property(assign)NSInteger sex;
@property(assign)NSInteger departId;
@property(strong)NSString *telphone;
@property(strong)NSString *email;
@property(strong)NSString *pyname;
@property(assign)NSInteger userStatus;
- (id)initWithUserID:(NSString*)userID name:(NSString*)name nick:(NSString*)nick avatar:(NSString*)avatar userRole:(NSInteger)userRole userUpdated:(NSUInteger)updated;
+(id)dicToUserEntity:(NSDictionary *)dic;
+(NSMutableDictionary *)userToDic:(DDUserEntity *)user;
-(void)sendEmail;
-(void)callPhoneNum;
-(NSString *)getAvatarUrl;
-(NSString *)getAvatarPreImageUrl;
-(id)initWithPB:(UserInfo *)pbUser;
+(UInt32)localIDTopb:(NSString *)userid;
+(NSString *)pbUserIdToLocalID:(NSUInteger)userID;
-(void)updateLastUpdateTimeToDB;
@end