//
//  DDChatImageCell.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-06-09.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "DDChatImageCell.h"
#import "UIImageView+WebCache.h"
#import "DDChatImagePreviewViewController.h"
#import "UIView+DDAddition.h"
#import "NSDictionary+JSON.h"
#import "PhotosCache.h"
#import "DDAppDelegate.h"
#import "DDDatabaseUtil.h"
#import "DDMessageSendManager.h"
#import "ChattingMainViewController.h"
#import "DDSendPhotoMessageAPI.h"
#import "SessionModule.h"
#import "UIImage+UIImageAddition.h"
@implementation DDChatImageCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.msgImgView =[[UIImageView alloc] init];
        self.msgImgView.userInteractionEnabled=NO;
        [self.msgImgView setClipsToBounds:YES];
        [self.msgImgView.layer setCornerRadius:3];
        [self.msgImgView setContentMode:UIViewContentModeScaleAspectFill];
        [self.contentView addSubview:self.msgImgView];
        [self.bubbleImageView setClipsToBounds:YES];
        self.photos = [NSMutableArray new];
    }
    return self;
}
-(void)showPreview
{
    if (self.msgImgView.image == nil) {
        return;
    }
    [self.photos removeAllObjects];
    [self.photos addObject:[MWPhoto photoWithImage:self.msgImgView.image]];
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = NO;
    browser.displayNavArrows = NO;
    browser.wantsFullScreenLayout = YES;
    browser.zoomPhotosToFill = YES;
    [browser setCurrentPhotoIndex:0];
    DDChatImagePreviewViewController *preViewControll = [DDChatImagePreviewViewController new];
    preViewControll.photos=self.photos;
    
    [[ChattingMainViewController shareInstance].navigationController pushViewController:preViewControll animated:YES];
}

- (void)setContent:(DDMessageEntity*)content
{
    
    [super setContent:content];
    if(content.msgContentType == DDMessageTypeImage)
    {
        NSDictionary* messageContent = [NSDictionary initWithJsonString:content.msgContent];
        if (!messageContent)
        {
            NSString* urlString = content.msgContent;
            urlString = [urlString stringByReplacingOccurrencesOfString:DD_MESSAGE_IMAGE_PREFIX withString:@""];
            urlString = [urlString stringByReplacingOccurrencesOfString:DD_MESSAGE_IMAGE_SUFFIX withString:@""];
            NSURL* url = [NSURL URLWithString:urlString];
            [self showSending];
            [self.msgImgView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [self showSendSuccess];
            }];
            
            return;
        }
        if (messageContent[DD_IMAGE_LOCAL_KEY])
        {
            //加载本地图片
            NSString* localPath = messageContent[DD_IMAGE_LOCAL_KEY];
            NSData* data = [[PhotosCache sharedPhotoCache] photoFromDiskCacheForKey:localPath];
            UIImage *image = [[UIImage alloc] initWithData:data];
            [self.msgImgView setImage:image];
        }
        else{
            //加载服务器上的图片
            NSString* url = messageContent[DD_IMAGE_URL_KEY];
            __weak DDChatImageCell* weakSelf = self;
            
            [self showSending];
            [self.msgImgView sd_setImageWithURL:[NSURL URLWithString:url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [weakSelf showSendSuccess];
                if (error) {
                    
                }
            }];
        }
        
    }
    
   
}
#pragma mark -
#pragma mark DDChatCellProtocol Protocol
- (CGSize)sizeForContent:(DDMessageEntity*)content
{
    float height = 133;
    float width = 80;
    return CGSizeMake(width, height);
}

- (float)contentUpGapWithBubble
{
    return 1;
}

- (float)contentDownGapWithBubble
{
    return 1;
}

- (float)contentLeftGapWithBubble
{
    switch (self.location)
    {
        case DDBubbleRight:
            return 1;
        case DDBubbleLeft:
            return 8.5;
    }
    return 0;
}

- (float)contentRightGapWithBubble
{
    switch (self.location)
    {
        case DDBubbleRight:
            return 6.5;
            break;
        case DDBubbleLeft:
            return 1;
            break;
    }
    return 0;
}

- (void)layoutContentView:(DDMessageEntity*)content
{
    float x = self.bubbleImageView.left + [self contentLeftGapWithBubble];
    float y = self.bubbleImageView.top + [self contentUpGapWithBubble];
    CGSize size = [self sizeForContent:content];
    [self.msgImgView setFrame:CGRectMake(x, y, size.width, size.height)];
}

- (float)cellHeightForMessage:(DDMessageEntity*)message
{
    return 27 + 2 * dd_bubbleUpDown;
}
- (void)dealloc
{
    self.photos = nil;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */
#pragma mark -
#pragma mark DDMenuImageView Delegate
- (void)clickTheSendAgain:(MenuImageView*)imageView
{
    //子类去继承
    if (self.sendAgain)
    {
        self.sendAgain();
    }
}
- (void)sendImageAgain:(DDMessageEntity*)message
{
    //子类去继承
    [self showSending];
    NSDictionary* dic = [NSDictionary initWithJsonString:message.msgContent];
    NSString* locaPath = dic[DD_IMAGE_LOCAL_KEY];
    __block UIImage* image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:locaPath];
    if (!image)
    {
        NSData* data = [[PhotosCache sharedPhotoCache] photoFromDiskCacheForKey:locaPath];
        image = [[UIImage alloc] initWithData:data];
        if (!image) {
            [self showSendFailure];
            return ;
        }
    }
    [[DDSendPhotoMessageAPI sharedPhotoCache] uploadImage:locaPath success:^(NSString *imageURL) {
        NSDictionary* tempMessageContent = [NSDictionary initWithJsonString:message.msgContent];
        NSMutableDictionary* mutalMessageContent = [[NSMutableDictionary alloc] initWithDictionary:tempMessageContent];
        [mutalMessageContent setValue:imageURL forKey:DD_IMAGE_URL_KEY];
        NSString* messageContent = [mutalMessageContent jsonString];
        message.msgContent = messageContent;
        image = nil;
        [[DDMessageSendManager instance] sendMessage:message isGroup:[message isGroupMessage] Session:[[SessionModule sharedInstance] getSessionById:message.sessionId] completion:^(DDMessageEntity* theMessage,NSError *error) {
            if (error)
            {
                DDLog(@"发送消息失败");
                message.state = DDMessageSendFailure;
                //刷新DB
                [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                    if (result)
                    {
                        [self showSendFailure];
                    }
                }];
            }
            else
            {
                //刷新DB
                message.state = DDmessageSendSuccess;
                //刷新DB
                [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                    if (result)
                    {
                        [self showSendSuccess];
                    }
                }];
            }
        } Error:^(NSError *error) {
            [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                if (result)
                {
                    [self showSendFailure];
                }
            }];
        }];
        
    } failure:^(id error) {
        message.state = DDMessageSendFailure;
        //刷新DB
        [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
            if (result)
            {
                [self showSendFailure];
            }
        }];
    }];
    
}
- (void)clickThePreview:(MenuImageView *)imageView
{
    //子类去继承
    if (self.preview)
    {
        self.preview();
    }
}
@end
