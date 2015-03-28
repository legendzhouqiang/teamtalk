//
//  MainViewControll.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-15.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "MainViewControll.h"
#import "RecentUsersViewController.h"
#import "ContactsViewController.h"
#import "MyProfileViewControll.h"
#import "DDClientStateMaintenanceManager.h"
#import "DDGroupModule.h"
#import "FinderViewController.h"
#import "LoginViewController.h"
#import "std.h"
#import "SessionEntity.h"
//#import "UIFont+SytemFontOverride.h"
@interface MainViewControll ()
@property(strong) UINavigationController *nv2;
@property(assign) NSUInteger clickCount;
@end

@implementation MainViewControll

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

    self.nv1= [[UINavigationController alloc] initWithRootViewController:[RecentUsersViewController shareInstance]];
    

    UIImage* conversationSelected = [[UIImage imageNamed:@"conversation_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
   
    self.nv1.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"消息" image:[UIImage imageNamed:@"conversation"] selectedImage:conversationSelected];
    self.nv1.tabBarItem.tag=0;//26 140 242
    [self.nv1.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObject:RGB(26, 140, 242) forKey:UITextAttributeTextColor] forState:UIControlStateSelected];
    
    UIImage* contactSelected = [[UIImage imageNamed:@"contact_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    UINavigationController *nv2= [[UINavigationController alloc] initWithRootViewController:[ContactsViewController new]];
    nv2.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"通讯录" image:[UIImage imageNamed:@"contact"] selectedImage:contactSelected];
    nv2.tabBarItem.tag=1;
    [nv2.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObject:RGB(26, 140, 242) forKey:UITextAttributeTextColor] forState:UIControlStateSelected];

    UIImage* findSelected = [[UIImage imageNamed:@"tab_nav_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    UINavigationController* nv3 = [[UINavigationController alloc] initWithRootViewController:[[FinderViewController alloc] init]];
    nv3.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"发现" image:[UIImage imageNamed:@"tab_nav"] selectedImage:findSelected];
    nv3.tabBarItem.tag = 2;
    [nv3.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObject:RGB(26, 140, 242) forKey:UITextAttributeTextColor] forState:UIControlStateSelected];

    
    UIImage* myProfileSelected = [[UIImage imageNamed:@"myprofile_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UINavigationController *nv4= [[UINavigationController alloc] initWithRootViewController:[MyProfileViewControll new]];
    nv4.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"我的" image:[UIImage imageNamed:@"myprofile"] selectedImage:myProfileSelected];
    nv4.tabBarItem.tag=3;

    [nv4.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObject:RGB(26, 140, 242) forKey:UITextAttributeTextColor] forState:UIControlStateSelected];
    
    self.viewControllers=@[self.nv1,nv2,nv3,nv4];
    self.delegate=self;
    self.title=@"TeamTalk";
    self.tabBar.translucent = YES;
   // [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

//    [[UINavigationBar appearance] setBarTintColor:[UIColor yellowColor]];
    
    // Do any additional setup after loading the view from its nib.
    
    // 设置字体 Hiragino Mincho ProN  Hiragino Kaku Gothic ProN  HiraKakuProN-W3
//    [[UILabel appearance] setFont:[UIFont fontWithName:@"FZLanTingHei-L-GBK" size:10.0]];
//    [self setFontFamily:@"FZLanTingHei-L-GBK" forView:self.view andSubViews:YES];
    
//
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if ([self.nv1.tabBarItem isEqual:item])
    {
        self.clickCount=self.clickCount+1;
        if (self.clickCount==2) {
            if ([[[RecentUsersViewController shareInstance].tableView visibleCells] count] > 0)
            {
                [[RecentUsersViewController shareInstance].items enumerateObjectsUsingBlock:^(SessionEntity *obj, NSUInteger idx, BOOL *stop) {
                    if (obj.unReadMsgCount) {
                        [[RecentUsersViewController shareInstance].tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                        return ;
                    }
                }];
                
            }
            self.clickCount=0;
        }
        
    }else{
    self.clickCount=0;
    }
}

@end
