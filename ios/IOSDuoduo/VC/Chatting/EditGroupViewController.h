//
//  EditGroupViewController.h
//  TeamTalk
//
//  Created by Michael Scofield on 2014-09-01.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupEntity.h"
#import "DDChattingEditViewController.h"
@class SessionEntity;
typedef void(^RefreshBlock)(NSString *sessionID);
@interface EditGroupViewController : RootViewController<UISearchBarDelegate,UISearchDisplayDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
@property(strong)NSMutableArray *users;
@property(copy)NSString *sessionID;
@property(strong)SessionEntity *session;
@property(assign)BOOL isGroupCreator;
@property(assign)BOOL isCreat;
@property(weak)GroupEntity *group;
@property(strong)DDChattingEditViewController *editControll;
@end
