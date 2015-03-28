//
//  DDEmotionCell.m
//  TeamTalk
//
//  Created by Michael Scofield on 2015-01-22.
//  Copyright (c) 2015 Michael Hu. All rights reserved.
//

#import "DDEmotionCell.h"
#import "EmotionsModule.h"
#import "DDMessageSendManager.h"
#import "UIView+DDAddition.h"
#import "SessionModule.h"
#import "UIImage+GIF.h"
@implementation DDEmotionCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.msgImgView.userInteractionEnabled=NO;
        [self.msgImgView setClipsToBounds:YES];
        [self.msgImgView setContentMode:UIViewContentModeScaleAspectFill];
        
    }
    return self;
}
#pragma mark -
#pragma mark DDChatCellProtocol Protocol
- (CGSize)sizeForContent:(DDMessageEntity*)content
{
    float height = 133;
    float width = 100;
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
- (void)setContent:(DDMessageEntity*)content
{
         [super setContent:content];
    NSString *emotionStr = content.msgContent;
    NSString *emotionImageStr = [[EmotionsModule shareInstance].emotionUnicodeDic objectForKey:emotionStr];
    NSArray *array = [emotionImageStr componentsSeparatedByString:@"."];
    UIImage *emotion = [UIImage sd_animatedGIFNamed:array[0]];
    if (emotion) {
        [self.msgImgView setImage:emotion];
        [self.bubbleImageView setHidden:YES];
    }
    
}
-(void)sendTextAgain:(DDMessageEntity *)message
{
    message.state = DDMessageSending;
    [self showSending];
    [[DDMessageSendManager instance] sendMessage:message isGroup:[message isGroupMessage]  Session:[[SessionModule sharedInstance] getSessionById:message.sessionId] completion:^(DDMessageEntity* theMessage,NSError *error) {
        
        [self showSendSuccess];
        
        
    } Error:^(NSError *error) {
        [self showSendFailure];
    }];
    
}
@end
