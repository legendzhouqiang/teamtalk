//
//  DDChattingMainViewController.m
//  IOSDuoduo
//
//  Created by 东邪 on 14-5-26.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "ChattingMainViewController.h"
#import "ChatUtilityViewController.h"
#import "std.h"
#import "PhotosCache.h"
#import "DDGroupModule.h"
#import "DDMessageSendManager.h"
#import "MsgReadACKAPI.h"
#import "DDDatabaseUtil.h"
#import "DDChatTextCell.h"
#import "DDChatVoiceCell.h"
#import "DDChatImageCell.h"
#import "DDChattingEditViewController.h"
#import "DDPromptCell.h"
#import "UIView+DDAddition.h"
#import "DDMessageModule.h"
#import "RecordingView.h"
#import "AnalysisImage.h"
#import "TouchDownGestureRecognizer.h"
#import "DDSendPhotoMessageAPI.h"
#import "NSDictionary+JSON.h"
#import "EmotionsModule.h"
#import "RuntimeStatus.h"
#import "DDEmotionCell.h"
#import "RecentUsersViewController.h"
#import "PublicProfileViewControll.h"
#import "UnAckMessageManager.h"
#import "GetMessageQueueAPI.h"
#import "GetLatestMsgId.h"

typedef NS_ENUM(NSUInteger, DDBottomShowComponent)
{
    DDInputViewUp                       = 1,
    DDShowKeyboard                      = 1 << 1,
    DDShowEmotion                       = 1 << 2,
    DDShowUtility                       = 1 << 3
};

typedef NS_ENUM(NSUInteger, DDBottomHiddComponent)
{
    DDInputViewDown                     = 14,
    DDHideKeyboard                      = 13,
    DDHideEmotion                       = 11,
    DDHideUtility                       = 7
};
//

typedef NS_ENUM(NSUInteger, DDInputType)
{
    DDVoiceInput,
    DDTextInput
};

typedef NS_ENUM(NSUInteger, PanelStatus)
{
    VoiceStatus,
    TextInputStatus,
    EmotionStatus,
    ImageStatus
};

#define DDINPUT_MIN_HEIGHT          44.0f
#define DDINPUT_HEIGHT              self.chatInputView.size.height
#define DDINPUT_BOTTOM_FRAME        CGRectMake(0, CONTENT_HEIGHT - self.chatInputView.height + NAVBAR_HEIGHT,FULL_WIDTH,self.chatInputView.height)
#define DDINPUT_TOP_FRAME           CGRectMake(0, CONTENT_HEIGHT - self.chatInputView.height + NAVBAR_HEIGHT - 216, FULL_WIDTH, self.chatInputView.height)
#define DDUTILITY_FRAME             CGRectMake(0, CONTENT_HEIGHT + NAVBAR_HEIGHT -216, FULL_WIDTH, 216)
#define DDEMOTION_FRAME             CGRectMake(0, CONTENT_HEIGHT + NAVBAR_HEIGHT-216, FULL_WIDTH, 216)
#define DDCOMPONENT_BOTTOM          CGRectMake(0, CONTENT_HEIGHT + NAVBAR_HEIGHT, FULL_WIDTH, 216)

@interface ChattingMainViewController ()<UIGestureRecognizerDelegate>
@property(nonatomic,assign)CGPoint inputViewCenter;
@property(nonatomic,strong)UIActivityIndicatorView *activity;
@property(assign)PanelStatus panelStatus;
@property(strong)NSString *chatObjectID;
@property(strong) UIButton *titleBtn ;
- (void)recentViewController;

- (UITableViewCell*)p_textCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDMessageEntity*)message;
- (UITableViewCell*)p_voiceCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDMessageEntity*)message;
- (UITableViewCell*)p_promptCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDPromptEntity*)prompt;

- (void)n_receiveMessage:(NSNotification*)notification;
- (void)p_clickThRecordButton:(UIButton*)button;
- (void)p_record:(UIButton*)button;
- (void)p_willCancelRecord:(UIButton*)button;
- (void)p_cancelRecord:(UIButton*)button;
- (void)p_sendRecord:(UIButton*)button;
- (void)p_endCancelRecord:(UIButton*)button;

- (void)p_tapOnTableView:(UIGestureRecognizer*)sender;
- (void)p_hideBottomComponent;

- (void)p_enableChatFunction;
- (void)p_unableChatFunction;

@end

@implementation ChattingMainViewController
{
    TouchDownGestureRecognizer* _touchDownGestureRecognizer;
    NSString* _currentInputContent;
    UIButton *_recordButton;
    DDBottomShowComponent _bottomShowComponent;
    float _inputViewY;
    int _type;
}
+(instancetype )shareInstance
{
    static dispatch_once_t onceToken;
    static ChattingMainViewController *_sharedManager = nil;
    dispatch_once(&onceToken, ^{
        _sharedManager = [ChattingMainViewController new];
    });
    return _sharedManager;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.view];
    if (CGRectContainsPoint(DDINPUT_BOTTOM_FRAME, location))
    {
        return NO;
    }
    return YES;
}

-(void)sendImageMessage:(Photo *)photo Image:(UIImage *)image
{
    NSDictionary* messageContentDic = @{DD_IMAGE_LOCAL_KEY:photo.localPath};
    NSString* messageContent = [messageContentDic jsonString];

    DDMessageEntity *message = [DDMessageEntity makeMessage:messageContent Module:self.module MsgType:DDMessageTypeImage];
    [self scrollToBottomAnimated:YES];
    NSData *photoData = UIImagePNGRepresentation(image);
    [[PhotosCache sharedPhotoCache] storePhoto:photoData forKey:photo.localPath toDisk:YES];
    //[self.chatInputView.textView setText:@""];
    [[DDDatabaseUtil instance] insertMessages:@[message] success:^{
        DDLog(@"消息插入DB成功");
        
    } failure:^(NSString *errorDescripe) {
        DDLog(@"消息插入DB失败");
    }];
    photo=nil;
    [[DDSendPhotoMessageAPI sharedPhotoCache] uploadImage:messageContentDic[DD_IMAGE_LOCAL_KEY] success:^(NSString *imageURL) {
        [self scrollToBottomAnimated:YES];
        message.state=DDMessageSending;
        NSDictionary* tempMessageContent = [NSDictionary initWithJsonString:message.msgContent];
        NSMutableDictionary* mutalMessageContent = [[NSMutableDictionary alloc] initWithDictionary:tempMessageContent];
        [mutalMessageContent setValue:imageURL forKey:DD_IMAGE_URL_KEY];
        NSString* messageContent = [mutalMessageContent jsonString];
        message.msgContent = messageContent;
        [self sendMessage:imageURL messageEntity:message];
        [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
        }];

    } failure:^(id error) {
        message.state = DDMessageSendFailure;
        //刷新DB
        [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
            if (result)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[_tableView reloadData];
//                    NSUInteger index = [self.module.showingMessages indexOfObject:message];
//                    [_tableView beginUpdates];
//                    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                    [_tableView reloadData];
                });
            }
        }];
        
    }];
}
- (void)textViewEnterSend
{
    //发送消息
    NSString* text = [self.chatInputView.textView text];
    
    NSString* parten = @"\\s";
    NSRegularExpression* reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:nil];
    NSString* checkoutText = [reg stringByReplacingMatchesInString:text options:NSMatchingReportProgress range:NSMakeRange(0, [text length]) withTemplate:@""];
    if ([checkoutText length] == 0)
    {
        return;
    }
    DDMessageContentType msgContentType = DDMessageTypeText;
    DDMessageEntity *message = [DDMessageEntity makeMessage:text Module:self.module MsgType:msgContentType];
    [self.chatInputView.textView setText:nil];
    [[DDDatabaseUtil instance] insertMessages:@[message] success:^{
        DDLog(@"消息插入DB成功");
    } failure:^(NSString *errorDescripe) {
        DDLog(@"消息插入DB失败");
    }];
    [self sendMessage:text messageEntity:message];
}

-(void)sendMessage:(NSString *)msg messageEntity:(DDMessageEntity *)message
{
    BOOL isGroup = [self.module.sessionEntity isGroup];
    [[DDMessageSendManager instance] sendMessage:message isGroup:isGroup Session:self.module.sessionEntity  completion:^(DDMessageEntity* theMessage,NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                message.state= theMessage.state;
//                NSUInteger index = [self.module.showingMessages indexOfObject:message];
//                [self.tableView beginUpdates];
//                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView reloadData];
                [self scrollToBottomAnimated:YES];
            });
    } Error:^(NSError *error) {
//        NSUInteger index = [self.module.showingMessages indexOfObject:message];
//        [self.tableView beginUpdates];
//        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadData];
    }];
}
//--------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark RecordingDelegate
- (void)recordingFinishedWithFileName:(NSString *)filePath time:(NSTimeInterval)interval
{
    NSMutableData* muData = [[NSMutableData alloc] init];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    int length = [RecorderManager sharedManager].recordedTimeInterval;
    if (length < 1 )
    {
        DDLog(@"录音时间太短");
        dispatch_async(dispatch_get_main_queue(), ^{
            [_recordingView setHidden:NO];
            [_recordingView setRecordingState:DDShowRecordTimeTooShort];
        });
        return;
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_recordingView setHidden:YES];
        });
    }
    int8_t ch[4];
    for(int32_t i = 0;i<4;i++){
        ch[i] = ((length >> ((3 - i)*8)) & 0x0ff);
    }
    [muData appendBytes:ch length:4];
    [muData appendData:data];
     DDMessageContentType msgContentType = DDMessageTypeVoice;
    DDMessageEntity* message = [DDMessageEntity makeMessage:filePath Module:self.module MsgType:msgContentType];
    BOOL isGroup = [self.module.sessionEntity isGroup];
    if (isGroup) {
        message.msgType=MsgTypeMsgTypeGroupAudio;
    }else
    {
        message.msgType = MsgTypeMsgTypeSingleAudio;
    }
    [message.info setObject:@(length) forKey:VOICE_LENGTH];
    [message.info setObject:@(1) forKey:DDVOICE_PLAYED];
    NSUInteger index = [self.module.showingMessages indexOfObject:message];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToBottomAnimated:YES];
        [[DDDatabaseUtil instance] insertMessages:@[message] success:^{
            NSLog(@"消息插入DB成功");
        } failure:^(NSString *errorDescripe) {
            NSLog(@"消息插入DB失败");
        }];
        
    });
    
    [[DDMessageSendManager instance] sendVoiceMessage:muData filePath:filePath forSessionID:self.module.sessionEntity.sessionID isGroup:isGroup Message:message Session:self.module.sessionEntity completion:^(DDMessageEntity *theMessage, NSError *error) {
        if (!error)
        {
            DDLog(@"发送语音消息成功");
            [[PlayerManager sharedManager] playAudioWithFileName:@"msg.caf" playerType:DDSpeaker delegate:self];
            message.state = DDmessageSendSuccess;
            [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
              
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_tableView beginUpdates];
//                         [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        [_tableView reloadData];
                    });
                
                
            }];
        }
        else
        {
            DDLog(@"发送语音消息失败");
            message.state = DDMessageSendFailure;
            [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
               
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_tableView beginUpdates];
//                         [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        [_tableView reloadData];
                    });
                
            }];
            
        }
    }];
}

- (void)playingStoped
{
    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.titleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.titleBtn.frame=CGRectMake(0, 0, 150, 40);
        [self.titleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.titleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [self.titleBtn addTarget:self action:@selector(titleTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.titleBtn.titleLabel setTextAlignment:NSTextAlignmentLeft];
    }
    return self;
}
-(void)notificationCenter
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(n_receiveMessage:)
                                                 name:DDNotificationReceiveMessage
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillShowKeyboard:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillHideKeyboard:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkSessionLastMsgIDThenUpdate:) name:@"ChattingSessionUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloginSuccess) name:@"ReloginSuccess" object:nil];
    

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self notificationCenter];
    [self initialInput];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(p_tapOnTableView:)];
    [self.tableView addGestureRecognizer:tap];
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(p_tapOnTableView:)];
    pan.delegate = self;
    [self.tableView addGestureRecognizer:pan];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    [self scrollToBottomAnimated:NO];
    
    //_originalTableViewContentInset = self.tableView.contentInset;
    
     self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
     self.activity.frame=CGRectMake(FULL_WIDTH/2, 70, 20, 20);
    
    [self.view addSubview:self.activity];
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"myprofile"] style:UIBarButtonItemStylePlain target:self action:@selector(Edit:)];
    self.navigationItem.rightBarButtonItem=item;
    [self.module addObserver:self forKeyPath:@"showingMessages" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [self.module addObserver:self forKeyPath:@"sessionEntity.sessionID" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.navigationItem.titleView setUserInteractionEnabled:YES];
    self.navigationItem.titleView=self.titleBtn;
    self.view.backgroundColor=[UIColor whiteColor];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    UIButton *backButton = [UIButton buttonWithType:101];
    [backButton addTarget:self action:@selector(p_popViewController) forControlEvents:UIControlEventTouchUpInside];
    [backButton setImage:[UIImage imageNamed:@"top_back"] forState:UIControlStateNormal];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.backBarButtonItem = backItem;

}

-(void)setThisViewTitle:(NSString *)title
{
     [self.titleBtn setTitle:title forState:UIControlStateNormal];
}
-(IBAction)Edit:(id)sender
{
    DDChattingEditViewController *chattingedit = [DDChattingEditViewController new];
    chattingedit.session=self.module.sessionEntity;
    self.title=@"";
    [self.navigationController pushViewController:chattingedit animated:YES];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)scrollToBottomAnimated:(BOOL)animated
{
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    if(rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:animated];
       
    }
   
}

- (ChattingModule*)module
{
    if (!_module)
    {
        _module = [[ChattingModule alloc] init];
    }
    return _module;
}

#pragma mark -
#pragma mark ActionMethods  发送sendAction 音频 voiceChange  显示表情 disFaceKeyboard
-(IBAction)sendAction:(id)sender{
    if (self.chatInputView.textView.text.length>0) {
        NSLog(@"点击发送");
        [self.chatInputView.textView setText:@""];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.chatInputView.textView setText:nil];
    [self.tabBarController.tabBar setHidden:YES];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self p_hideBottomComponent];
    
   
}
//- (void)checkSessionLastMsgIDThenUpdate:(NSNotification *)notification
//{
//    //用于在后台系统被系统杀死后恢复消息的
//    NSDictionary *sessionDic = [notification object];
//    SessionEntity *session =sessionDic[@"session"];
//    [self.module loadHisToryMessageFromServer:session.lastMsgID loadCount:session.unReadMsgCount Completion:^(NSUInteger addcount, NSError *error) {
//            self.module.sessionEntity.unReadMsgCount=0;
//        [self.tableView reloadData];
//        }];
//}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];


}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tabBarController.tabBar setHidden:NO];
    [self.module.ids removeAllObjects];
    [[PlayerManager sharedManager] stopPlaying];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ReloginSuccess" object:nil];
     [self.chatInputView resignFirstResponder];
}

#pragma mark -
#pragma mark UIGesture Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer.view isEqual:_tableView])
    {
        return YES;
    }
    return NO;
}

#pragma mark - EmojiFace Funcation
-(void)insertEmojiFace:(NSString *)string
{
    DDMessageContentType msgContentType = DDMEssageEmotion;
    DDMessageEntity *message = [DDMessageEntity makeMessage:string Module:self.module MsgType:msgContentType];
    [self.chatInputView.textView setText:nil];
    [[DDDatabaseUtil instance] insertMessages:@[message] success:^{
        DDLog(@"消息插入DB成功");
    } failure:^(NSString *errorDescripe) {
        DDLog(@"消息插入DB失败");
    }];
    [self sendMessage:string messageEntity:message];
//    NSMutableString* content = [NSMutableString stringWithString:self.chatInputView.textView.text];
//    [content appendString:string];
//    [self.chatInputView.textView setText:content];
    
}
-(void)deleteEmojiFace
{
    EmotionsModule* emotionModule = [EmotionsModule shareInstance];
    NSString* toDeleteString = nil;
    if (self.chatInputView.textView.text.length == 0)
    {
        return;
    }
    if (self.chatInputView.textView.text.length == 1)
    {
        self.chatInputView.textView.text = @"";
    }
    else
    {
        toDeleteString = [self.chatInputView.textView.text substringFromIndex:self.chatInputView.textView.text.length - 1];
        int length = [emotionModule.emotionLength[toDeleteString] intValue];
        if (length == 0)
        {
            toDeleteString = [self.chatInputView.textView.text substringFromIndex:self.chatInputView.textView.text.length - 2];
            length = [emotionModule.emotionLength[toDeleteString] intValue];
        }
        length = length == 0 ? 1 : length;
        self.chatInputView.textView.text = [self.chatInputView.textView.text substringToIndex:self.chatInputView.textView.text.length - length];
    }
    
}
#pragma mark - UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.module.showingMessages count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float height = 0;
    id object = self.module.showingMessages[indexPath.row];
    if ([object isKindOfClass:[DDMessageEntity class]])
    {
        DDMessageEntity* message = object;
        height = [self.module messageHeight:message];
    }
    else if([object isKindOfClass:[DDPromptEntity class]])
    {
        height = 30;
    }
    return height+10;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

        id object = self.module.showingMessages[indexPath.row];
        UITableViewCell* cell = nil;
        if ([object isKindOfClass:[DDMessageEntity class]])
        {
            DDMessageEntity* message = (DDMessageEntity*)object;
            if (message.msgContentType == DDMessageTypeText ) {
                cell = [self p_textCell_tableView:tableView cellForRowAtIndexPath:indexPath message:message];
            }else if (message.msgContentType == DDMessageTypeVoice)
            {
                cell = [self p_voiceCell_tableView:tableView cellForRowAtIndexPath:indexPath message:message];
            }
            else if(message.msgContentType == DDMessageTypeImage)
            {
                cell = [self p_imageCell_tableView:tableView cellForRowAtIndexPath:indexPath message:message];
            }else if (message.msgContentType == DDMEssageEmotion)
            {
                cell = [self p_emotionCell_tableView:tableView cellForRowAtIndexPath:indexPath message:message];
            }
            else
            {
                cell = [self p_textCell_tableView:tableView cellForRowAtIndexPath:indexPath message:message];
            }
            
        }
        else if ([object isKindOfClass:[DDPromptEntity class]])
        {
            DDPromptEntity* prompt = (DDPromptEntity*)object;
            cell = [self p_promptCell_tableView:tableView cellForRowAtIndexPath:indexPath message:prompt];
        }
        
        return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    static BOOL loadingHistory = NO;
 
     if (scrollView.contentOffset.y < -100 && [self.module.showingMessages count] > 0 && !loadingHistory)
     {
         loadingHistory = YES;
         self.hadLoadHistory=YES;
         [self.activity startAnimating];
         NSInteger preCount = [self.module.showingMessages count];
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [self.module loadMoreHistoryCompletion:^(NSUInteger addCount,NSError *error) {
                [self.activity stopAnimating];
                 loadingHistory=NO;
                 [self.tableView reloadData];
                 if (addCount) {
                     NSInteger index = [self.module.showingMessages count]-preCount;
                     [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                 }
                
             }];
         });
     }
}
#pragma mark PublicAPI
- (void)showChattingContentForSession:(SessionEntity*)session
{
    self.module.sessionEntity = nil;
    self.hadLoadHistory=NO;
    [self p_unableChatFunction];
    [self p_enableChatFunction];
    [self.module.showingMessages removeAllObjects];
    [self.tableView reloadData];
    self.module.sessionEntity = session;
    [self setThisViewTitle:session.name];
    [self.module loadMoreHistoryCompletion:^(NSUInteger addcount, NSError *error) {
        if (session.unReadMsgCount !=0 ) {
            MsgReadACKAPI* readACK = [[MsgReadACKAPI alloc] init];
            [readACK requestWithObject:@[self.module.sessionEntity.sessionID,@(self.module.sessionEntity.lastMsgID),@(self.module.sessionEntity.sessionType)] Completion:nil];
            self.module.sessionEntity.unReadMsgCount=0;
            [[DDDatabaseUtil instance] updateRecentSession:self.module.sessionEntity completion:^(NSError *error) {
                
            }];
            
        }
        
    }];
 }
#pragma mark - Text view delegatef

- (void)viewheightChanged:(float)height
{
    [self setValue:@(self.chatInputView.origin.y) forKeyPath:@"_inputViewY"];
}

#pragma mark PrivateAPI


- (UITableViewCell*)p_textCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDMessageEntity*)message
{
    static NSString* identifier = @"DDChatTextCellIdentifier";
    DDChatBaseCell* cell = (DDChatBaseCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[DDChatTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.session =self.module.sessionEntity;
    NSString* myUserID = [RuntimeStatus instance].user.objID;
    if ([message.senderId isEqualToString:myUserID])
    {
        [cell setLocation:DDBubbleRight];
    }
    else
    {
        [cell setLocation:DDBubbleLeft];
    }
    
    if (![[UnAckMessageManager instance] isInUnAckQueue:message] && message.state == DDMessageSending && [message isSendBySelf]) {
        message.state=DDMessageSendFailure;
    }
    [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
        
    }];

    [cell setContent:message];
    __weak DDChatTextCell* weakCell = (DDChatTextCell*)cell;
    cell.sendAgain = ^{
        [weakCell showSending];
        [weakCell sendTextAgain:message];
    };
    
    return cell;
}

- (UITableViewCell*)p_voiceCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDMessageEntity*)message
{
    static NSString* identifier = @"DDVoiceCellIdentifier";
    DDChatBaseCell* cell = (DDChatBaseCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[DDChatVoiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.session =self.module.sessionEntity;
    NSString* myUserID = [RuntimeStatus instance].user.objID;
    if ([message.senderId isEqualToString:myUserID])
    {
        [cell setLocation:DDBubbleRight];
    }
    else
    {
        [cell setLocation:DDBubbleLeft];
    }
    [cell setContent:message];
    __weak DDChatVoiceCell* weakCell = (DDChatVoiceCell*)cell;
    [(DDChatVoiceCell*)cell setTapInBubble:^{
        //播放语音
        if ([[PlayerManager sharedManager] playingFileName:message.msgContent]) {
            [[PlayerManager sharedManager] stopPlaying];
        }else{
            NSString* fileName = message.msgContent;
            [[PlayerManager sharedManager] playAudioWithFileName:fileName delegate:self];
            [message.info setObject:@(1) forKey:DDVOICE_PLAYED];
            [weakCell showVoicePlayed];
            [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
            }];

        }
        
    }];
    
    [(DDChatVoiceCell*)cell setEarphonePlay:^{
        //听筒播放
        NSString* fileName = message.msgContent;
        [[PlayerManager sharedManager] playAudioWithFileName:fileName playerType:DDEarPhone delegate:self];
        [message.info setObject:@(1) forKey:DDVOICE_PLAYED];
        [weakCell showVoicePlayed];

        [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
            
        }];

    }];
    
    [(DDChatVoiceCell*)cell setSpeakerPlay:^{
        //扬声器播放
        NSString* fileName = message.msgContent;
        [[PlayerManager sharedManager] playAudioWithFileName:fileName playerType:DDSpeaker delegate:self];
        [message.info setObject:@(1) forKey:DDVOICE_PLAYED];
        [weakCell showVoicePlayed];
        [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
            
        }];

    }];
    [(DDChatVoiceCell *)cell setSendAgain:^{
        //重发
         [weakCell showSending];
        [weakCell sendVoiceAgain:message];
    }];
    return cell;
}

- (UITableViewCell*)p_promptCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDPromptEntity*)prompt
{
    static NSString* identifier = @"DDPromptCellIdentifier";
    DDPromptCell* cell = (DDPromptCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[DDPromptCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSString* promptMessage = prompt.message;
    [cell setprompt:promptMessage];
    return cell;
}

- (UITableViewCell*)p_emotionCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDMessageEntity*)message
{
    static NSString* identifier = @"DDEmotionCellIdentifier";
    DDEmotionCell* cell = (DDEmotionCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[DDEmotionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.session =self.module.sessionEntity;
    NSString* myUserID =[RuntimeStatus instance].user.objID;
    if ([message.senderId isEqualToString:myUserID])
    {
        [cell setLocation:DDBubbleRight];
    }
    else
    {
        [cell setLocation:DDBubbleLeft];
    }
    
    [cell setContent:message];
    __weak DDEmotionCell* weakCell = cell;
    
    [cell setSendAgain:^{
        [weakCell sendTextAgain:message];
        
    }];
    
    [cell setTapInBubble:^{
    }];
    return cell;
}


- (UITableViewCell*)p_imageCell_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath message:(DDMessageEntity*)message
{
    static NSString* identifier = @"DDImageCellIdentifier";
    DDChatImageCell* cell = (DDChatImageCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[DDChatImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.session =self.module.sessionEntity;
    NSString* myUserID =[RuntimeStatus instance].user.objID;
    if ([message.senderId isEqualToString:myUserID])
    {
        [cell setLocation:DDBubbleRight];
    }
    else
    {
        [cell setLocation:DDBubbleLeft];
    }
    
    [[DDDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
        
    }];
    [cell setContent:message];
    __weak DDChatImageCell* weakCell = cell;
  
    [cell setSendAgain:^{
        [weakCell sendImageAgain:message];

    }];
    
    [cell setTapInBubble:^{
        [weakCell showPreview];
    }];
    
    [cell setPreview:cell.tapInBubble];
    
    return cell;
}



- (void)p_clickThRecordButton:(UIButton*)button
{
    switch (button.tag) {
        case DDVoiceInput:
            //开始录音
            [self p_hideBottomComponent];
            [button setImage:[UIImage imageNamed:@"dd_input_normal"] forState:UIControlStateNormal];
            button.tag = DDTextInput;
            [self.chatInputView willBeginRecord];
            [self.chatInputView.textView resignFirstResponder];
            _currentInputContent = self.chatInputView.textView.text;
            if ([_currentInputContent length] > 0)
            {
                [self.chatInputView.textView setText:nil];
            }
            break;
        case DDTextInput:
            //开始输入文字
            [button setImage:[UIImage imageNamed:@"dd_record_normal"] forState:UIControlStateNormal];
            button.tag = DDVoiceInput;
            [self.chatInputView willBeginInput];
            if ([_currentInputContent length] > 0)
            {
                [self.chatInputView.textView setText:_currentInputContent];
            }
            [self.chatInputView.textView becomeFirstResponder];
            break;
    }
}

- (void)p_record:(UIButton*)button
{
    [self.chatInputView.recordButton setHighlighted:YES];
    [self.chatInputView.buttonTitle setText:@"松开发送"];
    if (![[self.view subviews] containsObject:_recordingView])
    {
        [self.view addSubview:_recordingView];
    }
    [_recordingView setHidden:NO];
    [_recordingView setRecordingState:DDShowVolumnState];
    [[RecorderManager sharedManager] setDelegate:self];
    [[RecorderManager sharedManager] startRecording];
    DDLog(@"record");
}

- (void)p_willCancelRecord:(UIButton*)button
{
    [_recordingView setHidden:NO];
    [_recordingView setRecordingState:DDShowCancelSendState];
    DDLog(@"will cancel record");
}

- (void)p_cancelRecord:(UIButton*)button
{
    [self.chatInputView.recordButton setHighlighted:NO];
    [self.chatInputView.buttonTitle setText:@"按住说话"];
    [_recordingView setHidden:YES];
    [[RecorderManager sharedManager] cancelRecording];
    DDLog(@"cancel record");
}

- (void)p_sendRecord:(UIButton*)button
{
    [self.chatInputView.recordButton setHighlighted:NO];
    [self.chatInputView.buttonTitle setText:@"按住说话"];
    [[RecorderManager sharedManager] stopRecording];
    DDLog(@"send record");
}


- (void)p_endCancelRecord:(UIButton*)button
{
    [_recordingView setHidden:NO];
    [_recordingView setRecordingState:DDShowVolumnState];
}

- (void)p_tapOnTableView:(UIGestureRecognizer*)sender
{
    if (_bottomShowComponent)
    {
        [self p_hideBottomComponent];
    }
}

- (void)p_hideBottomComponent
{
    _bottomShowComponent = _bottomShowComponent & 0;
    //隐藏所有
    [self.chatInputView.textView resignFirstResponder];
    [UIView animateWithDuration:0.25 animations:^{
        [self.ddUtility.view setFrame:DDCOMPONENT_BOTTOM];
        [self.emotions.view setFrame:DDCOMPONENT_BOTTOM];
        [self.chatInputView setFrame:DDINPUT_BOTTOM_FRAME];
    }];

    [self setValue:@(self.chatInputView.origin.y) forKeyPath:@"_inputViewY"];
}

- (void)p_enableChatFunction
{
    [self.chatInputView setUserInteractionEnabled:YES];
}

- (void)p_unableChatFunction
{
    [self.chatInputView setUserInteractionEnabled:NO];
}

- (void)p_popViewController
{
    
    [self p_hideBottomComponent];
    //[self.navigationController popViewControllerAnimated:YES];
    self.title=@"";
    [self setThisViewTitle:@""];
}

#pragma mark -
#pragma mark DDEmotionViewCOntroller Delegate
- (void)emotionViewClickSendButton
{
    [self textViewEnterSend];
}

- (void)levelMeterChanged:(float)levelMeter
{
    [_recordingView setVolume:levelMeter];
}
#pragma mark -
#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"sessionEntity.sessionID"]) {
        if ([change objectForKey:@"new"] !=nil) {
            [self setThisViewTitle:self.module.sessionEntity.name];
        }
    }
    if ([keyPath isEqualToString:@"showingMessages"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            if (self.hadLoadHistory == NO) {
                [self scrollToBottomAnimated:NO];
            }
        });
    }
    if ([keyPath isEqualToString:@"_inputViewY"])
    {
        float maxY = FULL_HEIGHT - DDINPUT_MIN_HEIGHT;
        float gap = maxY - _inputViewY;
        [UIView animateWithDuration:0.25 animations:^{
            _tableView.contentInset = UIEdgeInsetsMake(_tableView.contentInset.top, 0, gap+60, 0);
            //_tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, gap, 0);
            
            if (_bottomShowComponent & DDShowEmotion)
            {
                [self.emotions.view setTop:self.chatInputView.bottom];
            }
            if (_bottomShowComponent & DDShowUtility)
            {
                [self.ddUtility.view setTop:self.chatInputView.bottom];
            }
            
        } completion:^(BOOL finished) {
        
        }];
        if (gap != 0)
        {
            [self scrollToBottomAnimated:NO];
        }
    }
    
}
@end

@implementation ChattingMainViewController(ChattingInput)

- (void)initialInput
{
    CGRect inputFrame = CGRectMake(0, CONTENT_HEIGHT - DDINPUT_MIN_HEIGHT + NAVBAR_HEIGHT,FULL_WIDTH,DDINPUT_MIN_HEIGHT);
    self.chatInputView = [[JSMessageInputView alloc] initWithFrame:inputFrame delegate:self];
    [self.chatInputView setBackgroundColor:RGB(249, 249, 249)];
    [self.view addSubview:self.chatInputView];
    [self.chatInputView.emotionbutton addTarget:self
                      action:@selector(showEmotions:)
            forControlEvents:UIControlEventTouchUpInside];
    
    [self.chatInputView.showUtilitysbutton addTarget:self
                           action:@selector(showUtilitys:)
                 forControlEvents:UIControlEventTouchDown];
    
    [self.chatInputView.voiceButton addTarget:self
                      action:@selector(p_clickThRecordButton:)
            forControlEvents:UIControlEventTouchUpInside];


    _touchDownGestureRecognizer = [[TouchDownGestureRecognizer alloc] initWithTarget:self action:nil];
    __weak ChattingMainViewController* weakSelf = self;
    _touchDownGestureRecognizer.touchDown = ^{
        [weakSelf p_record:nil];
    };
    
    _touchDownGestureRecognizer.moveInside = ^{
        [weakSelf p_endCancelRecord:nil];
    };
    
    _touchDownGestureRecognizer.moveOutside = ^{
        [weakSelf p_willCancelRecord:nil];
    };
    
    _touchDownGestureRecognizer.touchEnd = ^(BOOL inside){
        if (inside)
        {
            [weakSelf p_sendRecord:nil];
        }
        else
        {
            [weakSelf p_cancelRecord:nil];
        }
    };
    [self.chatInputView.recordButton addGestureRecognizer:_touchDownGestureRecognizer];
    _recordingView = [[RecordingView alloc] initWithState:DDShowVolumnState];
    [_recordingView setHidden:YES];
    [_recordingView setCenter:CGPointMake(FULL_WIDTH/2, self.view.centerY)];
    [self addObserver:self forKeyPath:@"_inputViewY" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

-(IBAction)showUtilitys:(id)sender
{
    [_recordButton setImage:[UIImage imageNamed:@"dd_record_normal"] forState:UIControlStateNormal];
    _recordButton.tag = DDVoiceInput;
    [self.chatInputView willBeginInput];
    if ([_currentInputContent length] > 0)
    {
        [self.chatInputView.textView setText:_currentInputContent];
    }
    
    if (self.ddUtility == nil)
    {
        self.ddUtility = [ChatUtilityViewController new];
        [self addChildViewController:self.ddUtility];
        self.ddUtility.view.frame=CGRectMake(0, self.view.size.height,FULL_WIDTH , 280);
        [self.view addSubview:self.ddUtility.view];
    }
    
    if (_bottomShowComponent & DDShowKeyboard)
    {
        //显示的是键盘,这是需要隐藏键盘，显示插件，不需要动画
        _bottomShowComponent = (_bottomShowComponent & 0) | DDShowUtility;
        [self.chatInputView.textView resignFirstResponder];
        [self.ddUtility.view setFrame:DDUTILITY_FRAME];
        [self.emotions.view setFrame:DDCOMPONENT_BOTTOM];
    }
    else if (_bottomShowComponent & DDShowUtility)
    {
        //插件面板本来就是显示的,这时需要隐藏所有底部界面
//        [self p_hideBottomComponent];
        [self.chatInputView.textView becomeFirstResponder];
        _bottomShowComponent = _bottomShowComponent & DDHideUtility;
    }
    else if (_bottomShowComponent & DDShowEmotion)
    {
        //显示的是表情，这时需要隐藏表情，显示插件
        [self.emotions.view setFrame:DDCOMPONENT_BOTTOM];
        [self.ddUtility.view setFrame:DDUTILITY_FRAME];
        _bottomShowComponent = (_bottomShowComponent & DDHideEmotion) | DDShowUtility;
    }
    else
    {
        //这是什么都没有显示，需用动画显示插件
        _bottomShowComponent = _bottomShowComponent | DDShowUtility;
        [UIView animateWithDuration:0.25 animations:^{
            [self.ddUtility.view setFrame:DDUTILITY_FRAME];
            [self.chatInputView setFrame:DDINPUT_TOP_FRAME];
        }];
        [self setValue:@(DDINPUT_TOP_FRAME.origin.y) forKeyPath:@"_inputViewY"];

    }
    
}

-(IBAction)showEmotions:(id)sender
{
    [_recordButton setImage:[UIImage imageNamed:@"dd_record_normal"] forState:UIControlStateNormal];
    _recordButton.tag = DDVoiceInput;
    [self.chatInputView willBeginInput];
    if ([_currentInputContent length] > 0)
    {
        [self.chatInputView.textView setText:_currentInputContent];
    }
    
    if (self.emotions == nil) {
        self.emotions = [EmotionsViewController new];
        [self.emotions.view setBackgroundColor:[UIColor whiteColor]];
        self.emotions.view.frame=DDCOMPONENT_BOTTOM;
        self.emotions.delegate = self;
        [self.view addSubview:self.emotions.view];
    }
    if (_bottomShowComponent & DDShowKeyboard)
    {
        //显示的是键盘,这是需要隐藏键盘，显示表情，不需要动画
        _bottomShowComponent = (_bottomShowComponent & 0) | DDShowEmotion;
        [self.chatInputView.textView resignFirstResponder];
        [self.emotions.view setFrame:DDEMOTION_FRAME];
        [self.ddUtility.view setFrame:DDCOMPONENT_BOTTOM];
    }
    else if (_bottomShowComponent & DDShowEmotion)
    {
        //表情面板本来就是显示的,这时需要隐藏所有底部界面
        [self.chatInputView.textView resignFirstResponder];
        _bottomShowComponent = _bottomShowComponent & DDHideEmotion;
    }
    else if (_bottomShowComponent & DDShowUtility)
    {
        //显示的是插件，这时需要隐藏插件，显示表情
        [self.ddUtility.view setFrame:DDCOMPONENT_BOTTOM];
        [self.emotions.view setFrame:DDEMOTION_FRAME];
        _bottomShowComponent = (_bottomShowComponent & DDHideUtility) | DDShowEmotion;
    }
    else
    {
        //这是什么都没有显示，需用动画显示表情
        _bottomShowComponent = _bottomShowComponent | DDShowEmotion;
        [UIView animateWithDuration:0.25 animations:^{
            [self.emotions.view setFrame:DDEMOTION_FRAME];
            [self.chatInputView setFrame:DDINPUT_TOP_FRAME];
        }];
        [self setValue:@(DDINPUT_TOP_FRAME.origin.y) forKeyPath:@"_inputViewY"];
    }
}
#pragma mark - KeyBoardNotification
- (void)handleWillShowKeyboard:(NSNotification *)notification
{
    CGRect keyboardRect;
    keyboardRect = [(notification.userInfo)[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    _bottomShowComponent = _bottomShowComponent | DDShowKeyboard;
    [UIView animateWithDuration:0.25 animations:^{
        [self.chatInputView setFrame:CGRectMake(0, keyboardRect.origin.y - DDINPUT_HEIGHT, self.view.size.width, DDINPUT_HEIGHT)];
    }];
    [self setValue:@(keyboardRect.origin.y - DDINPUT_HEIGHT) forKeyPath:@"_inputViewY"];

}

- (void)handleWillHideKeyboard:(NSNotification *)notification
{
    CGRect keyboardRect;
    keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    _bottomShowComponent = _bottomShowComponent & DDHideKeyboard;
    if (_bottomShowComponent & DDShowUtility)
    {
        //显示的是插件
        [UIView animateWithDuration:0.25 animations:^{
            [self.chatInputView setFrame:DDINPUT_TOP_FRAME];
        }];
        [self setValue:@(self.chatInputView.origin.y) forKeyPath:@"_inputViewY"];
    }
    else if (_bottomShowComponent & DDShowEmotion)
    {
        //显示的是表情
        [UIView animateWithDuration:0.25 animations:^{
            [self.chatInputView setFrame:DDINPUT_TOP_FRAME];
        }];
        [self setValue:@(self.chatInputView.origin.y) forKeyPath:@"_inputViewY"];

    }
    else
    {
        [self p_hideBottomComponent];
    }
}

-(IBAction)titleTap:(id)sender
{
    if ([self.module.sessionEntity isGroup]) {
        return;
    }
    [self.module getCurrentUser:^(DDUserEntity *user) {
    PublicProfileViewControll *profile = [PublicProfileViewControll new];
        profile.title=user.nick;
        profile.user=user;
        [self.navigationController pushViewController:profile animated:YES];
    }];
}

- (void)n_receiveMessage:(NSNotification*)notification
{
    if (![self.navigationController.topViewController isEqual:self])
    {
        //当前不是聊天界面直接返回
        NSLog(@"进来了");
        return;
    }
    
    DDMessageEntity* message = [notification object];
     UIApplicationState state =[UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateBackground) {
        if([message.sessionId isEqualToString:self.module.sessionEntity.sessionID])
        {
            [self.module addShowMessage:message];
            [self.module updateSessionUpdateTime:message.msgTime];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scrollToBottomAnimated:YES];
            });
        }
        return;
    }
    //显示消息

    if([message.sessionId isEqualToString:self.module.sessionEntity.sessionID])
    {
        [self.module addShowMessage:message];
        [self.module updateSessionUpdateTime:message.msgTime];
        [[DDMessageModule shareInstance]  sendMsgRead:message];
         //[self scrollToBottomAnimated:YES];
    }
    
}
- (void)recordingTimeout
{
    
}

- (void)recordingStopped  //录音机停止采集声音
{
    
}

- (void)recordingFailed:(NSString *)failureInfoString
{
    
}

- (void)levelMeterChanged:(float)levelMeter
{
    [_recordingView setVolume:levelMeter];
}
-(void)reloginSuccess
{
    [self.module getNewMsg:^(NSUInteger addcount, NSError *error) {
        [self.tableView reloadData];
    }];
}

@end
