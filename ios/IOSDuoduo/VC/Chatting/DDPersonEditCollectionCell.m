//
//  DDPersonEditCollectionCell.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-08-20.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "DDPersonEditCollectionCell.h"
#import "UIImageView+WebCache.h"
#import "std.h"
@implementation DDPersonEditCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.personIcon = [[UIImageView alloc] initWithFrame:CGRectMake(8.5, 8.5, 58, 58)];
        [self.personIcon setClipsToBounds:YES];
        [self.personIcon.layer setCornerRadius:4];
        [self.personIcon setContentMode:UIViewContentModeScaleAspectFill];
        [self.contentView addSubview:self.personIcon];
        
        self.name = [[UILabel alloc] initWithFrame:CGRectMake(8.5,74, 58, 13)];
        [self.name setTextAlignment:NSTextAlignmentCenter];
        [self.name setFont:[UIFont systemFontOfSize:13.0]];
        [self.name setTextColor:RGB(102, 102, 102)];
        [self.contentView addSubview:self.name];
        
        self.delImg = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 23.5, 23.5)];

        [self.delImg setImage:[UIImage imageNamed:@"delImage"] forState:UIControlStateNormal];
        //[self.delImg setBackgroundColor:[UIColor redColor]];
        [self.delImg setHidden:YES];
        [self.contentView addSubview:self.delImg];
        
        
    }
    return self;
}
-(void)setContent:(NSString *)name AvatarImage:(NSString *)urlString
{
        [self.name setText:name];
    if ([urlString isEqualToString:@"tt_group_manager_add_user_100x100.jpg"]) {
        self.tag=100;
        self.personIcon.image = [UIImage imageNamed:@"tt_group_manager_add_user"];
        
    }else if([urlString isEqualToString:@"tt_group_manager_delete_user_100x100.jpg"])
    {
        self.tag=100;
        self.personIcon.image = [UIImage imageNamed:@"tt_group_manager_delete_user"];
        
    }else
    {
        [self.personIcon sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"user_placeholder"]];
    }

}
-(IBAction)deletePerson:(id)sender
{
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
