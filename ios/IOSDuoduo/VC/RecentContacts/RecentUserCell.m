//
//  DDRecentUserCell.m
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-26.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "RecentUserCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSDate+DDAddition.h"
#import "UIView+DDAddition.h"
#import "std.h"
#import "RuntimeStatus.h"
#import "DDUserEntity.h"
#import "DDMessageModule.h"
#import "GroupAvatarImage.h"
#import "DDUserModule.h"
#import "SessionEntity.h"
#import "DDGroupModule.h"
#import <QuartzCore/QuartzCore.h>
#import "PhotosCache.h"
#import "DDDatabaseUtil.h"
@implementation RecentUserCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self){
        // 重新设置位置
        _avatarImageView.frame = CGRectMake(10, 10, 50, 50);
        _nameLabel.frame = CGRectMake(10+50+10, 14, SCREEN_WIDTH-70-10-60, 20);
        _dateLabel.frame = CGRectMake(FULL_WIDTH-10-60, 14, 60, 15);
        _lastmessageLabel.frame = CGRectMake(10+50+10, 40, SCREEN_WIDTH-10-10-50, 16);
        
        // 设置字体
        [_nameLabel setFont:systemFont(17)];
       // [_lastmessageLabel setFont:systemFont(8)];
        [_dateLabel setFont:systemFont(12)];

    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected)
    {
        [_nameLabel setTextColor:[UIColor whiteColor]];
        [_lastmessageLabel setTextColor:[UIColor whiteColor]];
        [_dateLabel setTextColor:[UIColor whiteColor]];
    }
    else
    {
        [_nameLabel setTextColor:[UIColor blackColor]];
        [_lastmessageLabel setTextColor:RGB(135, 135, 135)];
        [_dateLabel setTextColor:RGB(135, 135, 135)];
    }
    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated               // animate between regular and highlighted state
{
    if (highlighted && self.selected)
    {
        [_nameLabel setTextColor:[UIColor whiteColor]];
        [_lastmessageLabel setTextColor:[UIColor whiteColor]];
        [_dateLabel setTextColor:[UIColor whiteColor]];
    }
    else
    {
        [_nameLabel setTextColor:[UIColor blackColor]];
        [_lastmessageLabel setTextColor:RGB(135, 135, 135)];
        [_dateLabel setTextColor:RGB(135, 135, 135)];
    }
}

#pragma mark - public
- (void)setName:(NSString*)name
{
    if (!name)
    {
        [_nameLabel setText:@""];
    }
    else
    {
        [_nameLabel setText:name];
    }
}

- (void)setTimeStamp:(NSUInteger)timeStamp
{
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSString* dateString = [date transformToFuzzyDate];
    [_dateLabel setText:dateString];
}

- (void)setLastMessage:(NSString*)message
{
    if (!message)
    {
        [_lastmessageLabel setText:@"."];
    }
    else
    {
        [_lastmessageLabel setText:message];
    }
}

- (void)setAvatar:(NSString*)avatar
{
    
    [[_avatarImageView subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(UIView*)obj removeFromSuperview];
    }];
    
    NSURL* avatarURL = [NSURL URLWithString:avatar];
    [_avatarImageView setClipsToBounds:YES];
    [_avatarImageView.layer setCornerRadius:4.0];
    UIImage* placeholder = [UIImage imageNamed:@"user_placeholder"];
    [_avatarImageView sd_setImageWithURL:avatarURL placeholderImage:placeholder];
}

- (void)setUnreadMessageCount:(NSUInteger)messageCount
{
    if (messageCount == 0)
    {
        [self.unreadMessageCountLabel setHidden:YES];
    }
    else if (messageCount < 10)
    {
        [self.unreadMessageCountLabel setHidden:NO];
        CGPoint center = self.unreadMessageCountLabel.center;
        NSString* title = [NSString stringWithFormat:@"%li",messageCount];
        [self.unreadMessageCountLabel setText:title];
        [self.unreadMessageCountLabel setWidth:16];
        [self.unreadMessageCountLabel setCenter:center];
        [self.unreadMessageCountLabel.layer setCornerRadius:8];
    }
    else if (messageCount < 99)
    {
        [self.unreadMessageCountLabel setHidden:NO];
        CGPoint center = self.unreadMessageCountLabel.center;
        NSString* title = [NSString stringWithFormat:@"%li",messageCount];
        [self.unreadMessageCountLabel setText:title];
        [self.unreadMessageCountLabel setWidth:25];
        [self.unreadMessageCountLabel setCenter:center];
        [self.unreadMessageCountLabel.layer setCornerRadius:8];
    }
    else
    {
        [self.unreadMessageCountLabel setHidden:NO];
        CGPoint center = self.unreadMessageCountLabel.center;
        NSString* title = @"99+";
        [self.unreadMessageCountLabel setText:title];
        [self.unreadMessageCountLabel setWidth:34];
        [self.unreadMessageCountLabel setCenter:center];
        [self.unreadMessageCountLabel.layer setCornerRadius:8];
    }
}


-(void)setShowSession:(SessionEntity *)session
{
    [self setName:session.name];
    [self setUnreadMessageCount:session.unReadMsgCount];
    if ([session.lastMsg isKindOfClass:[NSString class]]) {
        if ([session.lastMsg rangeOfString:DD_MESSAGE_IMAGE_PREFIX].location != NSNotFound) {
            NSArray *array = [session.lastMsg componentsSeparatedByString:DD_MESSAGE_IMAGE_PREFIX];
            NSString *string = [array lastObject];
            if ([string rangeOfString:DD_MESSAGE_IMAGE_SUFFIX].location != NSNotFound) {
                [self setLastMessage:@"[图片]"];
            }else{
                [self setLastMessage:string];
            }
            
        }else if ([session.lastMsg hasSuffix:@".spx"])
        {
            [self setLastMessage:@"[语音]"];
        }
        else{
            [self setLastMessage:session.lastMsg];
            
        }
    }

   
    if (session.sessionType == SessionTypeSessionTypeSingle) {
      
        [[DDUserModule shareInstance] getUserForUserID:session.sessionID Block:^(DDUserEntity *user) {
          
            
            [[_avatarImageView subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [(UIView*)obj removeFromSuperview];
            }];
            [_avatarImageView setImage:nil];
             [self setAvatar:[user getAvatarUrl]];
        }];
    }else{
        [_avatarImageView setImage:nil];
        [[_avatarImageView subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(UIView*)obj removeFromSuperview];
        }];
       
        if (session.avatar)
        {
                NSData* data = [[PhotosCache sharedPhotoCache] photoFromDiskCacheForKey:session.avatar];
                UIImage *image = [[UIImage alloc] initWithData:data];
                if (image) {
                     [_avatarImageView setImage:image];
                }else{
                    [self loadGroupIcon:session key:session.avatar];
                }
        }else{
                [self loadGroupIcon:session key:session.avatar];

            }
    
        }
    
   [self setTimeStamp:session.timeInterval];
    if(session.unReadMsgCount)
    {
        //实时获取未读消息从接口
    }
}

-(void)loadGroupIcon:(SessionEntity *)session key:(NSString*)key
{
    NSString* keyName = [[NSString alloc] init];
    if (key) {
        keyName = key;
    }else{
        keyName = [[PhotosCache sharedPhotoCache] getKeyName];
        session.avatar=keyName;
//        [[DDDatabaseUtil instance] updateRecentSession:session completion:^(NSError *error) {
//            
//        }];
    }
    [[DDGroupModule instance] getGroupInfogroupID:session.sessionID completion:^(GroupEntity *group) {
        [self setName:group.name];
        [_avatarImageView setBackgroundColor:RGB(222, 224, 224)];
        NSMutableArray* avatars = [[NSMutableArray alloc] init];
        __block NSUInteger usedImageNumber = 0;
        __block NSUInteger groupUserCnt = [group.groupUserIds count];
        [group.groupUserIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 21, 21)];
            [imageView.layer setCornerRadius:2.0];
            [imageView setContentMode:UIViewContentModeScaleAspectFill];
            [imageView setClipsToBounds:YES];

            NSString* userID = (NSString*)obj;
            [[DDUserModule shareInstance] getUserForUserID:userID Block:^(DDUserEntity *user) {
                if (user)
                {
                    usedImageNumber++;
                    NSString* avatar = [user getAvatarUrl];
                    NSURL* avatarURL = [[NSURL alloc] initWithString:avatar];
                    [[SDWebImageManager sharedManager] downloadImageWithURL:avatarURL options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                        
                    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                        if (!image)
                        {
                            image = [UIImage imageNamed:@"user_placeholder"];
                        }
                        [imageView setImage:image];
                        [avatars addObject:imageView];
                        if (usedImageNumber >= 4 || usedImageNumber == groupUserCnt)
                        {
                            if ([avatars count] == 1)
                            {
                                UIImageView* imageView1 = avatars[0];
                                [imageView1 setCenter:CGPointMake(_avatarImageView.width / 2, _avatarImageView.height / 2)];
                            }
                            else if ([avatars count] == 2)
                            {
                                UIImageView* imageView1 = avatars[0];
                                [imageView1 setCenter:CGPointMake(_avatarImageView.width / 4 + 1, _avatarImageView.height / 2)];
                                
                                UIImageView* imageView2 = avatars[1];
                                [imageView2 setCenter:CGPointMake(_avatarImageView.width / 4 * 3, _avatarImageView.height / 2)];
                            }
                            else if ([avatars count] == 3)
                            {
                                UIImageView* imageView1 = avatars[0];
                                [imageView1 setCenter:CGPointMake(_avatarImageView.width / 2, _avatarImageView.height / 4 + 1)];
                                
                                UIImageView* imageView2 = avatars[1];
                                [imageView2 setCenter:CGPointMake(_avatarImageView.width / 4 + 1, _avatarImageView.height / 4 * 3)];
                                
                                UIImageView* imageView3 = avatars[2];
                                [imageView3 setCenter:CGPointMake(_avatarImageView.width / 4 * 3, _avatarImageView.height / 4 * 3)];
                                
                            }
                            else if ([avatars count] == 4)
                            {
                                UIImageView* imageView1 = avatars[0];
                                [imageView1 setCenter:CGPointMake(_avatarImageView.width / 4 + 1, _avatarImageView.height / 4 + 1)];
                                
                                UIImageView* imageView2 = avatars[1];
                                [imageView2 setCenter:CGPointMake(_avatarImageView.width / 4 * 3, _avatarImageView.height / 4 + 1)];
                                
                                UIImageView* imageView3 = avatars[2];
                                [imageView3 setCenter:CGPointMake(_avatarImageView.width / 4 + 1, _avatarImageView.height / 4 * 3)];
                                
                                UIImageView* imageView4 = avatars[3];
                                [imageView4 setCenter:CGPointMake(_avatarImageView.width / 4 * 3, _avatarImageView.height / 4 * 3)];
                            }
                            
                            [avatars enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                [_avatarImageView addSubview:obj];
                            }];
                            [_avatarImageView setClipsToBounds:YES];
                            [_avatarImageView.layer setCornerRadius:3.0];
                            UIImage *image = [self getImageFromView:_avatarImageView];
                            NSData *photoData = UIImagePNGRepresentation(image);
                            [[PhotosCache sharedPhotoCache] storePhoto:photoData forKey:keyName toDisk:YES];
                        }
                    }];
                }
                if (usedImageNumber >= 4 || usedImageNumber == groupUserCnt) {
                    *stop = YES;
                }
            }];
            
        }];
    }];
    

}
-(UIImage *)getImageFromView:(UIView *)orgView{
    CGSize s = orgView.bounds.size;
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [orgView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end