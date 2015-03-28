//
//  DDepartment.h
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-08-06.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMBaseDefine.pb.h"
@interface DDepartment : NSObject
@property(assign)NSInteger ID;
@property(assign)NSInteger parentID;
@property(strong)NSString *title;
@property(strong)NSString *description;
@property(strong)NSString *leader;
@property(assign)NSInteger priority;
@property(assign)NSInteger count;
+(id)departmentFromDic:(DepartInfo *)dic;
@end
