//
//  DDRecentUsersViewController.m
//  IOSDuoduo
//
//  Created by 独嘉 on 14-5-26.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "RecentUsersViewController.h"
#import "RecentUserCell.h"
#import "DDUserModule.h"
#import "DDMessageModule.h"
#import "ChattingMainViewController.h"
#import "SessionEntity.h"
#import "std.h"
#import "DDDatabaseUtil.h"
#import "LoginModule.h"
#import "DDClientState.h"
#import "RuntimeStatus.h"
#import "DDUserModule.h"
#import "DDGroupModule.h"
#import "DDFixedGroupAPI.h"
#import "SearchContentViewController.h"
#import "MBProgressHUD.h"
#import "SessionModule.h"
#import "BlurView.h"
#import "LoginViewController.h"
@interface RecentUsersViewController ()
@property(strong)UISearchDisplayController * searchController;
@property(strong)MBProgressHUD *hud;
@property(strong)NSMutableDictionary *lastMsgs;
@property(weak)IBOutlet UISearchBar *bar;
@property(strong)SearchContentViewController *searchContent;
@property(assign)NSInteger fixedCount;
- (void)n_receiveStartLoginNotification:(NSNotification*)notification;
- (void)n_receiveLoginFailureNotification:(NSNotification*)notification;
- (void)n_receiveRecentContactsUpdateNotification:(NSNotification*)notification;
@end

@implementation RecentUsersViewController

+ (instancetype)shareInstance
{
    static RecentUsersViewController* g_recentUsersViewController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_recentUsersViewController = [RecentUsersViewController new];
    });
    return g_recentUsersViewController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveLoginFailureNotification:) name:DDNotificationUserLoginFailure object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveLoginNotification:) name:DDNotificationUserLoginSuccess object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kickOffUser:) name:@"KickOffUser" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logout) name:DDNotificationLogout object:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title=@"消息";
    self.navigationItem.title=@"TeamTalk";
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    self.wantsFullScreenLayout=YES;
    self.items=[NSMutableArray new];
    [_tableView setFrame:self.view.frame];
    self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.bar.bounds));
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self.tableView setBackgroundColor:RGB(239,239,244)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData) name:@"RefreshRecentData" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveReLoginSuccessNotification) name:@"ReloginSuccess" object:nil];
    self.lastMsgs = [NSMutableDictionary new];
    [[SessionModule sharedInstance] loadLocalSession:^(bool isok) {
        if (isok) {
            [self.items addObjectsFromArray:[[SessionModule sharedInstance] getAllSessions]];
            [self.tableView reloadData];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[SessionModule sharedInstance] getRecentSession:^(NSUInteger count) {
                  
                        [self.items removeAllObjects];
                        [self.items addObjectsFromArray:[[SessionModule sharedInstance] getAllSessions]];
                        [self sortItems];
                        NSUInteger unreadcount =  [[self.items valueForKeyPath:@"@sum.unReadMsgCount"] integerValue];
                    [self setToolbarBadge:unreadcount];
                    
                }];
            });
            
        }
    }];
    [SessionModule sharedInstance].delegate=self;
    [self addCustomSearchControll];
  

}


-(void)addCustomSearchControll
{
    
    self.searchContent = [SearchContentViewController new];
    self.searchContent.viewController=self;
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.bar contentsController:self];
    self.searchController.delegate=self;
    
    self.searchController.searchResultsDataSource=self.searchContent.dataSource;
    self.searchController.searchResultsDelegate=self.searchContent.delegate;
    
}

-(void)sortItems
{
    [self.items removeAllObjects];
    [self.items addObjectsFromArray:[[SessionModule sharedInstance] getAllSessions]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeInterval" ascending:NO];
    [self.items sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [self.tableView reloadData];
    
}

-(void)refreshData
{
    [self.tableView reloadData];
    [self setToolbarBadge:0];
    [self sortItems];
}

-(void)setToolbarBadge:(NSUInteger)count
{

    if (count !=0) {
        if (count > 99)
        {
            [self.parentViewController.tabBarItem setBadgeValue:@"99+"];
        }
        else
        {
            [self.parentViewController.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%ld",count]];
        }
    }else
    {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
         [self.parentViewController.tabBarItem setBadgeValue:nil];
    }

}


-(void)searchContact
{
    
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSUInteger count =  [[self.items valueForKeyPath:@"@sum.unReadMsgCount"] integerValue];
    [self setToolbarBadge:count];
    [self.tableView reloadData];
    self.fixedCount = [TheRuntime getFixedTopCount];

}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tabBarController.tabBar setHidden:NO];
    [ChattingMainViewController shareInstance].module.sessionEntity=nil;
   
    if (!self.items) {
        self.items=[NSMutableArray new];
        [_tableView setFrame:self.view.frame];
        self.lastMsgs = [NSMutableDictionary new];
        [[SessionModule sharedInstance] loadLocalSession:^(bool isok) {
            if (isok) {
                [self.items addObjectsFromArray:[[SessionModule sharedInstance] getAllSessions]];
                [self.tableView reloadData];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[SessionModule sharedInstance] getRecentSession:^(NSUInteger count) {
                        
                        [self.items removeAllObjects];
                        [self.items addObjectsFromArray:[[SessionModule sharedInstance] getAllSessions]];
                        [self sortItems];
                        NSUInteger unreadcount =  [[self.items valueForKeyPath:@"@sum.unReadMsgCount"] integerValue];
                        [self setToolbarBadge:unreadcount];
                        
                    }];
                });
                
            }
        }];

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark public
- (void)showLinking
{
    self.title = @"正在连接...";
//    UIView* titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
//    
//    UIActivityIndicatorView* activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    [activity setFrame:CGRectMake(30, 0, 44, 44)];
//    
//    UILabel* linkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
//    [linkLabel setTextAlignment:NSTextAlignmentCenter];
//    [linkLabel setText:@"正在连接"];
//    
//    [activity startAnimating];
//    [titleView addSubview:activity];
//    [titleView addSubview:linkLabel];
//    
//    [self.navigationItem setTitleView:titleView];
}


#pragma mark - UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSString* cellIdentifier = [NSString stringWithFormat:@"DDRecentUserCellIdentifier_%ld",indexPath.row];
    RecentUserCell* cell = (RecentUserCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"RecentUserCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
   
    UIView *view = [[UIView alloc] initWithFrame:cell.bounds];
    view.backgroundColor=RGB(229, 229, 229);
    cell.selectedBackgroundView=view;
    NSInteger row = [indexPath row];
    [cell setShowSession:self.items[row]];
    [self preLoadMessage:self.items[row]];
 
    return cell;
}
-(void)sessionUpdate:(SessionEntity *)session Action:(SessionAction)action
{
    if ([self.items containsObject:session]) {
        if ([self.items indexOfObject:session] == 0) {
            [self.items removeObjectAtIndex:0];
            [self.items insertObject:session atIndex:0];
            [self.tableView reloadData];
          
        }else{
            NSUInteger index = [self.items indexOfObject:session];
            [self.items removeObjectAtIndex:index];
            [self.items insertObject:session atIndex:0];
            [self.tableView reloadData];
        }
    }else{
        [self.items insertObject:session atIndex:0];
        @try {
            [self.tableView reloadData];
        }
        @catch (NSException *exception) {
            DDLog(@"插入cell 动画失败");
        }
    }
    
    NSUInteger count =  [[self.items valueForKeyPath:@"@sum.unReadMsgCount"] integerValue];
    [self setToolbarBadge:count];
}
#pragma mark - UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = [indexPath row];
    SessionEntity *session = self.items[row];
    [ChattingMainViewController shareInstance].title=session.name;
    [[ChattingMainViewController shareInstance] showChattingContentForSession:session];
        [self.navigationController pushViewController:[ChattingMainViewController shareInstance] animated:YES];

    
}


-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    SessionEntity *session = self.items[row];
    [[SessionModule sharedInstance] removeSessionByServer:session];
    [self.items removeObjectAtIndex:row];
    [self setToolbarBadge:[[self.items valueForKeyPath:@"@sum.unReadMsgCount"] integerValue]];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
   
    return @"删除";
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    
    [self.searchController setActive:YES animated:YES];
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchContent searchTextDidChanged:searchText Block:^(bool done) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
}
- (void)n_receiveLoginFailureNotification:(NSNotification*)notification
{
    self.title = @"未连接";
}
- (void)n_receiveStartLoginNotification:(NSNotification*)notification
{
     self.title = @"TeamTalk";
}
- (void)n_receiveLoginNotification:(NSNotification*)notification
{
    self.title = @"TeamTalk";

}
-(void)logout
{
    self.items=nil;
}

-(void)kickOffUser:(NSNotification*)notification
{
    int type = [[notification object] intValue];
    [[NSUserDefaults standardUserDefaults] setObject:@(false) forKey:@"autologin"];
    LoginViewController *login = [LoginViewController new];
    login.isRelogin=YES;
    
    [self presentViewController:login animated:YES completion:^{
        TheRuntime.user =nil;
        TheRuntime.userID =nil;
        [[DDTcpClientManager instance] disconnect];
        [DDClientState shareInstance].userState = DDUserOffLineInitiative;
        SCLAlertView *alert = [SCLAlertView new];
        [alert showInfo:self title:@"注意" subTitle:@"你的账号在其他设备登陆了" closeButtonTitle:@"确定" duration:0];
        
    }];
}
-(void)n_receiveReLoginSuccessNotification
{
        self.title = @"TeamTalk";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SessionModule sharedInstance] getRecentSession:^(NSUInteger count) {
            
            [self.items removeAllObjects];
            [self.items addObjectsFromArray:[[SessionModule sharedInstance] getAllSessions]];
            [self sortItems];
            [self setToolbarBadge:count];
            
        }];
    });
}
-(void)preLoadMessage:(SessionEntity *)session
{
   
        [[DDDatabaseUtil instance] getLastestMessageForSessionID:session.sessionID completion:^(DDMessageEntity *message, NSError *error) {
            if (message) {
                if (message.msgID != session.lastMsgID ) {
                    [[DDMessageModule shareInstance] getMessageFromServer:session.lastMsgID currentSession:session count:20 Block:^(NSMutableArray *array, NSError *error) {
                        [[DDDatabaseUtil instance] insertMessages:array success:^{
                            
                        } failure:^(NSString *errorDescripe) {
                            
                        }];
                    }];
                }
            }else{
                if (session.lastMsgID !=0) {
                    [[DDMessageModule shareInstance] getMessageFromServer:session.lastMsgID currentSession:session count:20 Block:^(NSMutableArray *array, NSError *error) {
                        [[DDDatabaseUtil instance] insertMessages:array success:^{
                            
                        } failure:^(NSString *errorDescripe) {
                            
                        }];
                    }];
                }
               
            }
            
        }];
    
}

@end
