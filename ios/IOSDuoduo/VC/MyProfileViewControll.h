//
//  MyProfileViewControll.h
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-15.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DDUserEntity;
@interface MyProfileViewControll : UIViewController<UITableViewDataSource,UITableViewDelegate>
    @property(strong)IBOutlet UIView *profileView;
@property(weak)IBOutlet UILabel *nickName;
@property(weak)IBOutlet UILabel *realName;
@property(weak)IBOutlet UIImageView *avatar;
@property(weak)IBOutlet UIView *view1;
@property(weak)IBOutlet UIView *view2;
@property(weak)IBOutlet UITableView *tableView;
@property(weak)IBOutlet UILabel *versionLabel;
@property(weak)DDUserEntity *user;
-(IBAction)goPersonalProfile;
-(IBAction)clearCache:(id)sender;
-(IBAction)logout:(id)sender;
@end
