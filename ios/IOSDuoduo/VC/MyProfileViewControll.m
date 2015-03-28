//
//  MyProfileViewControll.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-15.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "MyProfileViewControll.h"
#import "PublicProfileViewControll.h"
#import "RuntimeStatus.h"
#import "UIImageView+WebCache.h"
#import "DDUserDetailInfoAPI.h"
#import "PhotosCache.h"
#import "LogoutAPI.h"
#import "LoginViewController.h"
#import "DDClientState.h"
#import "DDUserModule.h"
#import "DDDatabaseUtil.h"
#import "NSString+Additions.h"
@interface MyProfileViewControll ()

@end

@implementation MyProfileViewControll

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
    self.title=@"我";
    self.profileView.userInteractionEnabled=true;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goPersonalProfile)];
    [self.profileView addGestureRecognizer:singleTap];
    UIImage* placeholder = [UIImage imageNamed:@"user_placeholder"];
    [self.avatar sd_setImageWithURL:[NSURL URLWithString:[[RuntimeStatus instance].user getAvatarUrl]] placeholderImage:placeholder];
    [[DDUserModule shareInstance] getUserForUserID:[RuntimeStatus instance].user.objID Block:^(DDUserEntity *user) {
        self.user=user;
        self.realName.text=user.name;
        self.nickName.text=user.nick;
    }];

    // 头像圆角
    [_avatar.layer setMasksToBounds:YES];
    [_avatar.layer setCornerRadius:4];
    [self.view1 setBackgroundColor:RGB(236, 236, 236)];
    [self.view setBackgroundColor:[UIColor whiteColor]];

    [self.versionLabel setText:[NSString formatCurDayForVersion]];
    // Do any additional setup after loading the view from its nib.
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:NO];
  
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"MyProfileCellIdentifier";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = RGB(244, 245, 246);
    NSInteger row = [indexPath row];
    if (row == 0)
    {
        [cell.textLabel setText:@"清理缓存图片"];
        
    }
    else if (row == 1)
    {
        [cell.textLabel setText:@"退出"];
        
    }
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row==0) {
        [self clearCache:nil];
    }else{
        [self logout:nil];
    }
}
-(IBAction)clearCache:(id)sender
{
   __block SCLAlertView *alert = [SCLAlertView new];
    [alert addButton:@"确定" actionBlock:^{
        SCLAlertView *cleaning = [SCLAlertView new];
        [cleaning showWaiting:self title:nil subTitle:@"正在清理" closeButtonTitle:nil duration:0];
        [[PhotosCache sharedPhotoCache] clearAllCache:^(bool isfinish) {
            if (isfinish) {
                [cleaning hideView];
                SCLAlertView *notice = [SCLAlertView new];
                [notice showSuccess:self title:nil subTitle:@"清理完成" closeButtonTitle:nil duration:2.0];
            }
        }];
        
        
    }];
    [alert showNotice:self title:@"提示" subTitle:@"是否清理图片缓存" closeButtonTitle:@"取消" duration:0];
    
}


-(IBAction)logout:(id)sender
{

    SCLAlertView *alert = [SCLAlertView new];
    [alert addButton:@"确定" actionBlock:^{
        LogoutAPI *logout = [LogoutAPI new];
        [logout requestWithObject:nil Completion:^(id response, NSError *error) {
            
        }];
        [DDNotificationHelp postNotification:DDNotificationLogout userInfo:nil object:nil];
        LoginViewController *login = [LoginViewController new];
        login.isRelogin=YES;
        [self presentViewController:login animated:YES completion:^{
            TheRuntime.user =nil;
            TheRuntime.userID =nil;
            [DDClientState shareInstance].userState = DDUserOffLineInitiative;
            [[DDTcpClientManager instance] disconnect];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"autologin"];
        }];

    }];
    [alert showNotice:self title:@"提示" subTitle:@"是否确认退出?" closeButtonTitle:@"取消" duration:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)goPersonalProfile
{
    PublicProfileViewControll *public = [PublicProfileViewControll new] ;
    public.user = self.user;
    [self.navigationController pushViewController:public animated:YES];
}

@end
