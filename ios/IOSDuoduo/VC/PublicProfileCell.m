//
//  PublicProfileCell.m
//  TeamTalk
//
//  Created by scorpio on 14/12/18.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "PublicProfileCell.h"
#import "std.h"

@implementation PublicProfileCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _descLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 15, 30, 15)];
        [_descLabel setFont:systemFont(15)];
        [_descLabel setTextColor:RGB(164, 165, 169)];
        [self.contentView addSubview:_descLabel];
        
        _detailLabel = [[UILabel alloc]initWithFrame:CGRectMake(70, 12, 250, 20)];
        [_descLabel setFont:systemFont(15)];
        [self.contentView addSubview:_detailLabel];
        
        _phone = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-15-12, 16, 12, 13)];
        [_phone setImage:[UIImage imageNamed:@"phone"]];
        [_phone setHidden:YES];
        [self.contentView addSubview:_phone];
        
    }
    return self;
}

- (void)setDesc:(NSString *)desc detail:(NSString *)detail{
    [_descLabel setText:desc];
    [_detailLabel setText:detail];
}

- (void)hidePhone:(BOOL)hide{
    [_phone setHidden:hide];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
