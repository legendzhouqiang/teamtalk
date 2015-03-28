//
//  PublieProfileViewControll.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-16.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "PublicProfileViewControll.h"
#import "DDUserEntity.h"
#import "SessionEntity.h"
#import "UIImageView+WebCache.h"
#import "ContactsModule.h"
#import "UIImageView+WebCache.h"
#import "ChattingMainViewController.h"
#import "RuntimeStatus.h"
#import "DDUserDetailInfoAPI.h"
#import "DDDatabaseUtil.h"
#import "DDAppDelegate.h"
#import "DDUserModule.h"
#import "PublicProfileCell.h"
@interface PublicProfileViewControll ()
@property(weak)IBOutlet UILabel *nickName;
@property(weak)IBOutlet UILabel *realName;
@property(weak)IBOutlet UIImageView *avatar;
@property(weak)IBOutlet UITableView *tableView;
@property(weak)IBOutlet UIButton *conversationBtn;
-(IBAction)startConversation:(id)sender;
@end

@implementation PublicProfileViewControll

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.nickName.text = self.user.nick;
    self.realName.text = self.user.name;
    self.realName.text = self.user.name;
    if([self.user.objID isEqualToString:TheRuntime.user.objID])
    {
        [self.conversationBtn setHidden:YES];
    }else
    {
        [self.conversationBtn setHidden:NO];
    }
    [self setTitle:@"详细资料"];
    [self initData];
    

    // Do any additional setup after loading the view from its nib.
}

-(void)initData
{
    UIImage* placeholder = [UIImage imageNamed:@"user_placeholder"];
    [self.avatar sd_setImageWithURL:[NSURL URLWithString:[self.user getAvatarUrl]] placeholderImage:placeholder];
    [self.avatar setClipsToBounds:YES];
    [self.avatar.layer setCornerRadius:7.5];
    [self.avatar setUserInteractionEnabled:YES];
    [self.tableView setContentInset:UIEdgeInsetsMake(-63, 0, 0, 0)];

    self.conversationBtn.layer.masksToBounds = YES;
    self.conversationBtn.layer.cornerRadius = 4;
//    UIView *view = [UIView new];
//    view.backgroundColor = [UIColor clearColor];
//    [self.tableView setTableFooterView:view];
//    [self.tableView setTableHeaderView:view];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tabBarController.tabBar setHidden:NO];
}
-(void)favThisContact
{
    [ContactsModule favContact:self.user];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PublicProfileCell";
    PublicProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier ];
    if (cell == nil) {
        cell = [[PublicProfileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    switch (indexPath.row) {
        case 0:
            {
                [[DDDatabaseUtil instance] getDepartmentTitleById:self.user.departId Block:^(NSString *title) {
                     [cell setDesc:@"部门" detail:title];
                }];
                cell.userInteractionEnabled = NO;
                [cell hidePhone:YES];
            }
            break;
        case 1:
            {
                [cell setDesc:@"手机" detail:self.user.telphone];
                [cell hidePhone:NO];
            }
            break;
        case 2:
        {
            [cell setDesc:@"邮箱" detail:self.user.email];
            [cell hidePhone:YES];
        }
            break;
        default:
            break;
    }
    
    return cell;
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100) {
        if (buttonIndex == 1) {
            [self callPhoneNum:self.user.telphone];
        }
    }else
    {
        if (buttonIndex == 1) {
            [self sendEmail:self.user.email];
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 1:{
            NSString *alertMsg;
            alertMsg = [NSString stringWithFormat:@"呼叫%@?",self.user.telphone];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:alertMsg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            alert.tag=100;
            [alert show];
        }
            break;
        case 2:{
            NSString *alertMsg;
            alertMsg = [NSString stringWithFormat:@"发送邮件%@?",self.user.email];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:alertMsg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            alert.tag=101;
            [alert show];
        }
            break;
            
        default:
            break;
    }
}
-(void)callPhoneNum:(NSString *)phoneNum
{
    if (!phoneNum) {
        return;
    }
    NSString *stringURL =[NSString stringWithFormat:@"tel:%@",phoneNum];
    NSURL *url = [NSURL URLWithString:stringURL];
    [[UIApplication sharedApplication] openURL:url];
}
-(void)sendEmail:(NSString *)address
{
    if (!address.length) {
        return;
    }
    NSString *stringURL =[NSString stringWithFormat:@"mailto:%@",address];
    NSURL *url = [NSURL URLWithString:stringURL];
    [[UIApplication sharedApplication] openURL:url];
}
-(IBAction)startConversation:(id)sender
{
     SessionEntity* session = [[SessionEntity alloc] initWithSessionID:self.user.objID type:SessionTypeSessionTypeSingle];
    [[ChattingMainViewController shareInstance] showChattingContentForSession:session];
    NSLog(@"%@...",TheAppDel.nv);
    if ([[self.navigationController viewControllers] containsObject:[ChattingMainViewController shareInstance]]) {
         [self.navigationController popToViewController:[ChattingMainViewController shareInstance] animated:YES];
    }else
    {
        [self.navigationController pushViewController:[ChattingMainViewController shareInstance] animated:YES];

    }
   
    
}

/*设置标题头的宽度*/
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}
/*设置标题尾的宽度*/
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
