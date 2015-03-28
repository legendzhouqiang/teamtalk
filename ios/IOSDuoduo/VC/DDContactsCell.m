//
//  DDContactsCell.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-08-22.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "DDContactsCell.h"
#import "std.h"
#import "UIImageView+WebCache.h"
#import "GroupEntity.h"
#import "DDUserModule.h"
#import "UIView+DDAddition.h"
@implementation DDContactsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.frame=CGRectMake(15, 5, 40, 40);
        self.button.showsTouchWhenHighlighted=YES;
        [self addSubview:self.button];
        self.avatar = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 36, 36)];
        [self.avatar setClipsToBounds:YES];
//        [self.avatar.layer setCornerRadius:2.0];
        [self.avatar setUserInteractionEnabled:YES];
        [self.avatar setContentMode:UIViewContentModeScaleAspectFill];
        [self.contentView addSubview:self.avatar];
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 20, 37, 18)];
        [self.nameLabel setFont:[UIFont systemFontOfSize:17.0]];
        [self.nameLabel setTextColor:[UIColor blackColor]];
        [self.contentView addSubview:self.nameLabel];
        self.cnameLabel = [[UILabel alloc] initWithFrame:CGRectMake(95, 23, 50, 15)];
        [self.cnameLabel setFont:[UIFont systemFontOfSize:12.0]];
        [self.cnameLabel setTextColor:RGB(170, 170, 170)];
        [self.contentView addSubview:self.cnameLabel];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
        self.selectedBackgroundView.backgroundColor = RGB(244, 245, 246);
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setCellContent:(NSString *)avatar Name:(NSString *)name Cname:(NSString *)cname
{
    [[self.avatar subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(UIView*)obj removeFromSuperview];
    }];
    self.nameLabel.text=name;
//    self.cnameLabel.text=cname;
    self.cnameLabel.text=@"";
    UIImage* placeholder = [UIImage imageNamed:@"user_placeholder"];
    
    // 群长度特殊处理
    CGSize size = [name sizeWithFont:systemFont(17) constrainedToSize:CGSizeMake(250, 1000000) lineBreakMode:NSLineBreakByWordWrapping];
    NSLog(@"%f,%f",size.height,size.width);
    NSLog(@"%@name",name);
    CGRect temp = self.nameLabel.frame;
    temp.size.height = size.height;
    temp.size.width = size.width;
    self.nameLabel.frame = temp;
    
    [self.avatar sd_setImageWithURL:[NSURL URLWithString:avatar] placeholderImage:placeholder];
}

- (void)setGroupAvatar:(GroupEntity*)group
{
    [self.avatar setBackgroundColor:[UIColor grayColor]];
    [self.avatar setImage:nil];
    [[self.avatar subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(UIView*)obj removeFromSuperview];
    }];
    
    NSMutableArray* avatars = [[NSMutableArray alloc] init];
    [group.groupUserIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
        [imageView.layer setCornerRadius:2.0];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setClipsToBounds:YES];
        NSString* userID = (NSString*)obj;
        [[DDUserModule shareInstance] getUserForUserID:userID Block:^(DDUserEntity *user) {
            if(user){
                NSString* avatar = [user getAvatarUrl];
                NSURL* avatarURL = [[NSURL alloc] initWithString:avatar];
                [imageView sd_setImageWithURL:avatarURL placeholderImage:[UIImage imageNamed:@"user_placeholder"]];
            }
        }];
        [avatars addObject:imageView];
        if ([avatars count] >= 4)
        {
            *stop = YES;
        }
    }];
    if ([avatars count] == 1)
    {
        UIImageView* imageView1 = avatars[0];
        [imageView1 setCenter:CGPointMake(self.avatar.width / 2, self.avatar.height / 2)];
    }
    else if ([avatars count] == 2)
    {
        UIImageView* imageView1 = avatars[0];
        [imageView1 setCenter:CGPointMake(self.avatar.width / 4 + 1, self.avatar.height / 2)];
        
        UIImageView* imageView2 = avatars[1];
        [imageView2 setCenter:CGPointMake(self.avatar.width / 4 * 3, self.avatar.height / 2)];
    }
    else if ([avatars count] == 3)
    {
        UIImageView* imageView1 = avatars[0];
        [imageView1 setCenter:CGPointMake(self.avatar.width / 2, self.avatar.height / 4 + 1)];
        
        UIImageView* imageView2 = avatars[1];
        [imageView2 setCenter:CGPointMake(self.avatar.width / 4 + 1, self.avatar.height / 4 * 3)];
        
        UIImageView* imageView3 = avatars[2];
        [imageView3 setCenter:CGPointMake(self.avatar.width / 4 * 3, self.avatar.height / 4 * 3)];
    }
    else if ([avatars count] == 4)
    {
        UIImageView* imageView1 = avatars[0];
        [imageView1 setCenter:CGPointMake(self.avatar.width / 4 + 1, self.avatar.height / 4 + 1)];
        
        UIImageView* imageView2 = avatars[1];
        [imageView2 setCenter:CGPointMake(self.avatar.width / 4 * 3, self.avatar.height / 4 + 1)];
        
        UIImageView* imageView3 = avatars[2];
        [imageView3 setCenter:CGPointMake(self.avatar.width / 4 + 1, self.avatar.height / 4 * 3)];
        
        UIImageView* imageView4 = avatars[3];
        [imageView4 setCenter:CGPointMake(self.avatar.width / 4 * 3, self.avatar.height / 4 * 3)];
    }
    [avatars enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.avatar addSubview:obj];
    }];
}

@end
