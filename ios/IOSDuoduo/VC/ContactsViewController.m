//
//  ContactsViewController.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-15.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "ContactsViewController.h"
#import "std.h"
#import "PublicProfileViewControll.h"
#import "ContactsModule.h"
#import "GroupEntity.h"
#import "DDSearch.h"
#import "ContactAvatarTools.h"
#import "DDContactsCell.h"
#import "DDUserDetailInfoAPI.h"
#import "DDGroupModule.h"
#import "ChattingMainViewController.h"
#import "SearchContentViewController.h"
#import "MBProgressHUD.h"
#import "DDFixedGroupAPI.h"
@interface ContactsViewController ()
@property(strong)UISegmentedControl *seg;
@property(strong)NSMutableDictionary *items;
@property(strong)NSMutableDictionary *department;
@property(strong)NSMutableDictionary *keys;
@property(strong)ContactsModule *model;
@property(strong)NSArray *allIndexes;
@property(strong)NSArray *departmentIndexes;
@property(strong)NSMutableArray *groups;
@property(strong)NSArray *searchResult;
@property(strong)UITableView *tableView;
@property(strong)UISearchBar *searchBar;
@property(strong)ContactAvatarTools *tools;
@property(strong)UISearchDisplayController *searchController;
@property(strong)SearchContentViewController *searchContent;
@property(strong)MBProgressHUD *hud;
@property(assign)int selectIndex;
@end

@implementation ContactsViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.hud];
    self.hud.dimBackground = YES;
    self.hud.labelText=@"正在加载...";
    [self.hud show:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllContacts) name:@"refreshAllContacts" object:nil];

    self.title=@"联系人";
    self.model = [ContactsModule new];
    self.groups = [NSMutableArray arrayWithArray:self.model.groups];
    self.searchResult = [NSArray new];
    self.seg = [[UISegmentedControl alloc] initWithItems:@[@"全部",@"部门"]];
    self.seg.selectedSegmentIndex=0;
    self.seg.frame=CGRectMake(80.0f, 8.0f, 200.0f, 30.0f);
    self.seg.segmentedControlStyle= UISegmentedControlStyleBar;//设置
    self.seg.backgroundColor = [UIColor whiteColor];
    self.seg.tintColor= RGB(1, 175, 244);
    
    [self.seg addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView=self.seg;
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, FULL_WIDTH, 40)];
    [self.searchBar setPlaceholder:@"搜索"];
    
    self.searchBar.searchBarStyle = UIBarStyleDefault;
    self.searchBar.barTintColor = RGB(220, 221, 224);
    //[self.searchBar setBackgroundColor:[UIColor whiteColor]];
    self.searchBar.layer.borderWidth = 0.5;
    self.searchBar.layer.borderColor = RGB(204, 204, 204).CGColor;
  //  [self.searchBar setBackgroundImage:[UIImage imageNamed:@"search_bar.png"] ];
    self.searchBar.delegate=self;
   // [self.view addSubview:self.searchBar];
   
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, FULL_WIDTH,(self.tabBarController.tabBar.isHidden?self.view.frame.size.height:self.view.frame.size.height-110))];
    self.tableView.delegate=self;
    self.tableView.tag=100;
    self.tableView.dataSource=self;
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView=self.searchBar;
    DDFixedGroupAPI *getFixgroup = [DDFixedGroupAPI new];
    [getFixgroup requestWithObject:nil Completion:^(NSArray *response, NSError *error) {
      
        [response enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop){
            NSString *groupID = [TheRuntime changeOriginalToLocalID:[obj[@"groupid"] integerValue] SessionType:SessionTypeSessionTypeGroup];
            NSInteger version = [obj[@"version"] integerValue];
           GroupEntity *group = [[DDGroupModule instance] getGroupByGId:groupID];
            if (group) {
                if (group.objectVersion == version) {
                    [self.groups addObject:group];
                }else{
                    [[DDGroupModule instance] getGroupInfogroupID:groupID completion:^(GroupEntity *group) {
                        [self.groups addObject:group];
                        
                    }];
                }
            }else{
                 [[DDGroupModule instance] getGroupInfogroupID:groupID completion:^(GroupEntity *group) {
                      [self.groups addObject:group];
                 }];
            }
        
        }];
           [self.tableView reloadData];
    }];
      self.department = [self.model sortByDepartment];
    [self swichContactsToALl];
    
    // 右侧索引颜色透明
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexColor=RGB(102, 102, 102);
    
    self.title=@"通讯录";
    self.allIndexes = [NSArray new];
    self.departmentIndexes = [NSArray new];
    [self addCustomSearchControll];
}
-(void)addCustomSearchControll
{
    
    self.searchContent = [SearchContentViewController new];
    self.searchContent.viewController=self;
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchController.delegate=self;
    self.searchController.searchResultsDataSource=self.searchContent.dataSource;
    self.searchController.searchResultsDelegate=self.searchContent.delegate;

    
}
-(void)scrollToTitle:(NSNotification *)notification
{
    NSString *string = [notification object];
    self.sectionTitle=string;
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.sectionTitle=nil;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.isSearchResult) {
        [self.tabBarController.tabBar setHidden:YES];
    }else
    {
        [self.tabBarController.tabBar setHidden:NO];
    }
    if (self.sectionTitle) {
        [self.seg setSelectedSegmentIndex:1];
        self.selectIndex=1;
        [self swichToShowDepartment];
        if ([self.allKeys count]) {
            int location = [self.allKeys indexOfObject:self.sectionTitle];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:location] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        return;
    }

   
}
-(void)refreshAllContacts
{
    if (self.sectionTitle) {
        [self.seg setSelectedSegmentIndex:1];
        self.selectIndex=1;
        [self swichToShowDepartment];
        int location = [self.allKeys indexOfObject:self.sectionTitle];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:location] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        return;
    }

    switch (self.selectIndex) {
        case 0:
            [self swichContactsToALl];
            break;
        case 1:
            [self swichToShowDepartment];
        default:
            break;
    }
    

}



-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
-(void)swichContactsToALl
{
    //[self.items removeAllObjects];
    self.items = [self.model sortByContactFirstLetter];
    [self.tableView reloadData];
}
-(void)swichToShowDepartment
{
    // [self.items removeAllObjects];
    //self.items = [self.model sortByDepartment];
    [self.tableView reloadData];
}
-(NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    if (self.selectIndex == 1) {
        [[self allKeys] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
 
            NSString *text =[self.model.department objectForKey:obj];
            char firstLetter = getFirstChar(text);
            NSString *fl = [[NSString stringWithFormat:@"%c",firstLetter] uppercaseString];
            if(![array containsObject:fl]){
                [array addObject:fl];
            }
        }];
    }
    else
    {
        NSArray* allKeys = [self allKeys];
        [allKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [array addObject:[obj uppercaseString]];
        }];
    }
    return array ;
}
-(IBAction)segmentAction:(UISegmentedControl *)sender
{
    int index = sender.selectedSegmentIndex;
    switch (index) {
        case 0:
            self.selectIndex=0;
            [self swichContactsToALl];
            break;
        case 1:
            self.selectIndex=1;
            [self swichToShowDepartment];
        default:
            break;
    }
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
-(NSArray*)allKeys{
    if (self.selectIndex == 1) {
        if ([self.departmentIndexes count]) {
            return self.departmentIndexes;
        }else{
            self.departmentIndexes =[[self.department allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                char char1 = getFirstChar(obj1);
                NSString *fl1 = [[NSString stringWithFormat:@"%c",char1] uppercaseString];
                char char2 = getFirstChar(obj2);
                NSString *fl2 = [[NSString stringWithFormat:@"%c",char2] uppercaseString];
                return [fl1 compare:fl2];}];
                return  self.departmentIndexes;
        }

    }else{
        if ([self.allIndexes count]) {
            return self.allIndexes;
        }else{
            self.allIndexes =[[self.items allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                char char1 = getFirstChar(obj1);
                NSString *fl1 = [[NSString stringWithFormat:@"%c",char1] uppercaseString];
                char char2 = getFirstChar(obj2);
                NSString *fl2 = [[NSString stringWithFormat:@"%c",char2] uppercaseString];
                return [fl1 compare:fl2];
            }];
            return self.allIndexes;
        }
}
    
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.selectIndex == 0) {
         return [[self.items allKeys] count]+1;
    }else{
      return [[self.department allKeys] count];
    }
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        if (self.selectIndex == 0) {
            if (section == 0) {
                return [self.groups count];
            }
            else
            {
                NSString *keyStr = [self allKeys][(NSUInteger) (section - 1)];
                NSArray *arr = (self.items)[keyStr];
                return [arr count];
            }
        }else{
            NSString *keyStr = [self allKeys][(NSUInteger) (section)];
            NSArray *arr = (self.department)[keyStr];
            return [arr count];
        }
    

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(self.selectIndex == 0 && section == 0){
        return 0;
    }
    return 22;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *text;
    if (self.selectIndex == 0) {
        if (section == 0) {
            text = @"";
        }else{
            text = [self.allKeys[section - 1] uppercaseString];
        }
    }else
    {
        text = [self.allKeys[section] uppercaseString];
        text =[self.model.department objectForKey:text];
    }
    UIView *sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 22)];
    [sectionHeadView setBackgroundColor:RGB(240, 240, 245)];
    UILabel *sectionHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 4.5, SCREEN_WIDTH, 13)];
    [sectionHeaderLabel setText:text];
    [sectionHeaderLabel setTextColor:RGB(144,144, 148)];
    [sectionHeaderLabel setFont:systemFont(13)];
    [sectionHeadView addSubview:sectionHeaderLabel];
    return sectionHeadView;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSInteger count;
    if (self.selectIndex == 0) {
        count = 1;
    }else{
        count = 0;
    }
    for(NSString *character in [self allKeys]){
        char firstLetter = getFirstChar(character);
        NSString *fl = [[NSString stringWithFormat:@"%c",firstLetter] uppercaseString];
        if([fl isEqualToString:title]){
            return count;
        }
        count ++;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"contactsCell";
    DDContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier ];
    if (cell == nil) {
        cell = [[DDContactsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
        if (self.selectIndex == 0) {
            if (indexPath.section == 0) {

                GroupEntity *group = [self.groups objectAtIndex:indexPath.row];
                 [cell setCellContent:nil Name:group.name Cname:@""];
                [cell setGroupAvatar:group];
                [cell.button setEnabled:NO];
            }
            else
            {
                NSString *keyStr = [[self allKeys] objectAtIndex:indexPath.section-1];
                NSArray *userArray =[self.items objectForKey:keyStr];
                DDUserEntity *user = [userArray objectAtIndex:indexPath.row];
         
                [cell setCellContent:[user getAvatarUrl] Name:user.nick Cname:user.name];
                cell.button.tag=indexPath.row;
                [cell.button setTitle:keyStr forState:UIControlStateNormal];
                [cell.button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
                [cell.button addTarget:self action:@selector(showActions:) forControlEvents:UIControlEventTouchUpInside];
            }
        }else
        {
            NSString *keyStr = [[self allKeys] objectAtIndex:indexPath.section];
            NSArray *userArray =[self.department objectForKey:keyStr];
            DDUserEntity *user = [userArray objectAtIndex:indexPath.row];
            [cell setCellContent:[user getAvatarUrl] Name:user.nick Cname:user.name];
            cell.button.tag=indexPath.row;
            [cell.button setTitle:keyStr forState:UIControlStateNormal];
            [cell.button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(showActions:) forControlEvents:UIControlEventTouchUpInside];
        }
    
    return cell;
}

-(IBAction)showActions:(id)sender
{
    if (self.tools.isShow) {
        [self.tools hiddenSelf];
    }
    UIButton *btn = (UIButton *)sender;
    NSArray *userArray;
    if(self.selectIndex == 0)
    {
       userArray =[self.items objectForKey:btn.titleLabel.text];
    }else{
        userArray =[self.department objectForKey:btn.titleLabel.text];
    }
    
    DDBaseEntity *user = [userArray objectAtIndex:btn.tag];
    CGRect rect = [self.tableView convertRect:self.tableView.frame fromView:btn];
    self.tools = [[ContactAvatarTools alloc] initWithFrame:CGRectMake(rect.origin.x+btn.frame.size.width+5, rect.origin.y-70, 100, 100)];
    __weak ContactsViewController *weakSelf = self;
    if ([user isKindOfClass:[DDUserEntity class]]) {
        self.tools.block=^(int index){
            switch (index) {
                case 1:
                    [weakSelf callNum:user];
                    break;
                case 2:
                    [weakSelf sendEmail:user];
                    break;
                case 3:
                    [weakSelf chatTo:user];
                default:
                    break;
            }
        };
    }
    [self.tableView addSubview:self.tools];
}

-(void)callNum:(DDUserEntity *)user
{
    if (user == nil) {
        return;
    }
    NSString *string = [NSString stringWithFormat:@"tel:%@",user.telphone];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];
}
-(void)sendEmail:(DDUserEntity *)user
{
    if (user == nil) {
    return;
    }
    NSString *string = [NSString stringWithFormat:@"mailto:%@",user.email];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];
}
-(void)chatTo:(DDUserEntity *)user
{
    if (user == nil) {
        return;
    }
    SessionEntity* session = [[SessionEntity alloc] initWithSessionID:user.objID type:SessionTypeSessionTypeSingle];
    [session setSessionName:user.nick];
    [[ChattingMainViewController shareInstance] showChattingContentForSession:session];
    [self.navigationController pushViewController:[ChattingMainViewController shareInstance] animated:YES];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.tools.isShow) {
        [self.tools hiddenSelf];
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.tools.isShow) {
        [self.tools hiddenSelf];
        return;
    }
        if (self.selectIndex == 0) {
            if (indexPath.section == 0) {
                GroupEntity *group = [self.groups objectAtIndex:indexPath.row];
                SessionEntity *session = [[SessionEntity alloc] initWithSessionID:group.objID type:SessionTypeSessionTypeGroup];
                [session setSessionName:group.name];
                ChattingMainViewController *main = [ChattingMainViewController shareInstance];
                [main showChattingContentForSession:session];
                [self.navigationController pushViewController:main animated:YES];
                return;
            }
            NSString *keyStr = [[self allKeys] objectAtIndex:indexPath.section-1];
            NSArray *userArray =[self.items objectForKey:keyStr];
            DDUserEntity *user;
            user = [userArray objectAtIndex:indexPath.row];
            PublicProfileViewControll *public = [PublicProfileViewControll new];
            public.user=user;
            [self.navigationController pushViewController:public animated:YES];
    }else
    {
        NSString *keyStr = [[self allKeys] objectAtIndex:indexPath.section];
        NSArray *userArray =[self.department objectForKey:keyStr];
        DDUserEntity *user;
        user = [userArray objectAtIndex:indexPath.row];
        PublicProfileViewControll *public = [PublicProfileViewControll new];
        public.user=user;
        [self.navigationController pushViewController:public animated:YES];

    }
   
}
-(CGFloat )tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self == [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    }
    return self;
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton=YES;
    [self.searchController setActive:YES animated:YES];
    return YES;
    
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchContent searchTextDidChanged:searchText Block:^(bool done) {
         [self.searchDisplayController.searchResultsTableView reloadData];
    }];
}
@end