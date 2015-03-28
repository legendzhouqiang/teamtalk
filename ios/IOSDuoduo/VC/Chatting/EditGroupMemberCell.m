//
//  EditGroupMemberCell.m
//  TeamTalk
//
//  Created by scorpio on 14/12/24.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "EditGroupMemberCell.h"

@implementation EditGroupMemberCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        _name = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [_name setFont:[UIFont systemFontOfSize:12]];
        [_name setBackgroundColor:[UIColor redColor]];
        [self.contentView addSubview:_name];
        
    }
    return self;
}

@end
