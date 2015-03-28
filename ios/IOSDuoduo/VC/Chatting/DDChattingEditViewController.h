//
//  DDChattingEditViewController.h
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-17.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SessionEntity.h"
#import "GroupEntity.h"
@interface DDChattingEditViewController : RootViewController<UITableViewDataSource,UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate>
@property(assign)BOOL isGroup;
@property(strong)NSString *groupName;
@property(nonatomic,strong)NSMutableArray *items;
@property(strong)SessionEntity *session;
@property(strong)GroupEntity *group;
-(void)refreshUsers:(NSMutableArray *)array;
@end
