//
//  DDepartment.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-08-06.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "DDepartment.h"

@implementation DDepartment
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ID = 0;
        self.parentID=0;
        self.title=@"";
        self.description=@"";
        self.leader=@"";
       // self.status=0;
        self.count=0;

    }
    return self;
}
+(id)departmentFromDic:(DepartInfo *)info
{
    return info;
}
@end
