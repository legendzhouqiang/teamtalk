//
//  DDLoginViewController.m
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-26.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "LoginViewController.h"
#import "ChattingMainViewController.h"
#import "RecentUsersViewController.h"
#import "DDClientStateMaintenanceManager.h"
#import "DDUserModule.h"
#import "DDMessageModule.h"
#import "LoginModule.h"
#import "SendPushTokenAPI.h"
#import "DDNotificationHelp.h"
#import "std.h"
#import "DDAppDelegate.h"
#import "ContactsModule.h"
#import "RuntimeStatus.h"
#import "MainViewControll.h"
#import "DDDatabaseUtil.h"
#import "DDGroupModule.h"
#import "MBProgressHUD.h"
@interface LoginViewController ()
@property(assign)CGPoint defaultCenter;
@end

@implementation LoginViewController

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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"ipaddress"] == nil) {
        [defaults setObject:@"http://access.teamtalk.im:8080/msg_server" forKey:@"ipaddress"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"username"]!=nil) {
        _userNameTextField.text =[[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"password"]!=nil) {
        _userPassTextField.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    }
    if(!self.isRelogin)
    {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"username"] && [[NSUserDefaults standardUserDefaults] objectForKey:@"password"])
        {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"autologin"] boolValue] == YES) {
                
                [self login:nil];
            }
            
            
        }
        
        
    }
    
    
    
    self.defaultCenter=self.view.center;
    self.userNameTextField.leftViewMode=UITextFieldViewModeAlways;
    self.userPassTextField.leftViewMode=UITextFieldViewModeAlways;
    UIImageView *usernameLeftView = [[UIImageView alloc] init];
    usernameLeftView.contentMode = UIViewContentModeCenter;
    usernameLeftView.frame=CGRectMake(0, 0, 18, 22.5);
    UIImageView *pwdLeftView = [[UIImageView alloc] init];
    pwdLeftView.contentMode = UIViewContentModeCenter;
    pwdLeftView.frame=CGRectMake(0, 0,18, 22.5);
    self.userNameTextField.leftView=usernameLeftView;
    self.userPassTextField.leftView=pwdLeftView;
    [self.userNameTextField.layer setBorderColor:RGB(211, 211, 211).CGColor];
    [self.userNameTextField.layer setBorderWidth:0.5];
    [self.userNameTextField.layer setCornerRadius:4];
    [self.userPassTextField.layer setBorderColor:RGB(211, 211, 211).CGColor];
    [self.userPassTextField.layer setBorderWidth:0.5];
    [self.userPassTextField.layer setCornerRadius:4];
    
    [self.userLoginBtn.layer setCornerRadius:4];
    
    // 设置用户名
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillShowKeyboard)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillHideKeyboard)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}
-(void)handleWillShowKeyboard
{
    [UIView animateWithDuration:0.2 animations:^{
        self.view.center=CGPointMake(self.view.center.x, self.defaultCenter.y-(IPHONE4?120:40));
    }];
}
-(void)handleWillHideKeyboard
{
    [UIView animateWithDuration:0.2 animations:^{
        self.view.center=self.defaultCenter;
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)hiddenKeyboard:(id)sender
{
    [_userNameTextField resignFirstResponder];
    [_userPassTextField resignFirstResponder];
}

- (IBAction)login:(UIButton*)button
{
    
    [self.userLoginBtn setEnabled:NO];
    NSString* userName = _userNameTextField.text ;
    NSString* password = _userPassTextField.text ;
    if (userName.length ==0 || password.length == 0) {
        [self.userLoginBtn setEnabled:YES];
        return;
    }
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    [HUD show:YES];
    HUD.dimBackground = YES;
    HUD.labelText = @"正在登录";
    SCLAlertView *alert = [SCLAlertView new];
    [[LoginModule instance] loginWithUsername:userName password:password success:^(DDUserEntity *user) {
        [self.userLoginBtn setEnabled:YES];
        if (user) {
            TheRuntime.user=user ;
            [TheRuntime updateData];
            
            if (TheRuntime.pushToken) {
                SendPushTokenAPI *pushToken = [[SendPushTokenAPI alloc] init];
                [pushToken requestWithObject:TheRuntime.pushToken Completion:^(id response, NSError *error) {
                    
                }];
            }
            if (self.isRelogin) {
                TheAppDel.mainViewControll=nil;
                TheAppDel.window.rootViewController=[MainViewControll new];
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }else{
                [DDGroupModule instance];
                [self presentViewController:TheAppDel.mainViewControll animated:YES completion:^{
                    
                }];
            }
            
        }
    } failure:^(NSString *error) {
        
        [self.userLoginBtn setEnabled:YES];
        [HUD removeFromSuperview];
        
        [alert showError:self title:@"错误" subTitle:error closeButtonTitle:@"确定" duration:0];
        //[TheRuntime showAlertView:@" " Description:error];
    }];
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self login:nil];
    return YES;
}
-(IBAction)showEditServerAddress:(id)sender
{
    SCLAlertView *alert = [SCLAlertView new];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UITextField *addressField = [alert addTextField:@"请填写服务器地址"];
    addressField.text=[defaults objectForKey:@"ipaddress"];
    [alert addButton:@"确定" actionBlock:^{
        [defaults setObject:addressField.text forKey:@"ipaddress"];
    }];
    [alert showEdit:self title:@"编辑服务器地址" subTitle:@"请填写你的服务器地址，或使用我们的测试服务器" closeButtonTitle:@"关闭" duration:0];
}
@end
