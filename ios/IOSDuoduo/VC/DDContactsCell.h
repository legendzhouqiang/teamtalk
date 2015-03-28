//
//  DDContactsCell.h
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-08-22.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupEntity.h"
@interface DDContactsCell : UITableViewCell
@property(strong)UIButton *button;
@property(strong)UIImageView *avatar;
@property(strong)UILabel *nameLabel;
@property(strong)UILabel *cnameLabel;
-(void)setCellContent:(NSString *)avater Name:(NSString *)name Cname:(NSString *)cname;
-(void)setGroupAvatar:(GroupEntity*)group;
@end
