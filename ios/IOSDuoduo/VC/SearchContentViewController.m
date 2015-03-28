//
//  SearchContentViewController.m
//  TeamTalk
//
//  Created by Michael Scofield on 2014-10-20.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "SearchContentViewController.h"
#import "std.h"
#import "DDSearch.h"
#import "DDContactsCell.h"
#import "DDUserEntity.h"
#import "PublicProfileViewControll.h"
#import "SessionEntity.h"
#import "ContactsViewController.h"
#import "DDAppDelegate.h"
#import "MBProgressHUD.h"
#import "ContactsModule.h"
#import "DDDatabaseUtil.h"
#import "SpellLibrary.h"
#import "DDGroupModule.h"
#import "DDUserModule.h"
#import "SessionModule.h"
#import "ChattingMainViewController.h"
@interface SearchContentViewController ()
@property(strong)NSMutableArray *groups;
@property(strong)NSString *keyString;
@property(strong) ContactsViewController *contact;
@property(strong)NSMutableArray *searchResult;
@property(strong)NSMutableArray *department;
@end

@implementation SearchContentViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.groups = [NSMutableArray new];
        
        self.searchResult = [NSMutableArray new];
        self.department = [NSMutableArray new];
        self.keyString=@"";
        self.dataSource=self;
        self.delegate=self;
        DDLog(@"come to");
        if ([[SpellLibrary instance] isEmpty]) {
            DDLog(@"spelllibrary is empty");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[[DDUserModule shareInstance] getAllMaintanceUser] enumerateObjectsUsingBlock:^(DDUserEntity *obj, NSUInteger idx, BOOL *stop) {
                    [[SpellLibrary instance] addSpellForObject:obj];
                    [[SpellLibrary instance] addDeparmentSpellForObject:obj];
                    
                }];
                NSArray *array =  [[DDGroupModule instance] getAllGroups];
                [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [[SpellLibrary instance] addSpellForObject:obj];
                }];
                
            });
        }
    }
    return self;
}


-(void)searchTextDidChanged:(NSString *)searchText Block:(void(^)(bool done)) block
{
    if ([searchText isEqualToString:@""]) {
        return ;
    }

    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self];
    [self addSubview:HUD];
    [HUD show:YES];
    HUD.dimBackground = YES;
    HUD.labelText = @"正在搜索";
    [[DDSearch instance] searchDepartment:searchText completion:^(NSArray *result, NSError *error) {
        if ([result count] >0) {
            [self.department removeAllObjects];
            [result enumerateObjectsUsingBlock:^(DDUserEntity *obj, NSUInteger idx, BOOL *stop) {
                if (![self.department containsObject:obj.department]) {
                    [self.department addObject:obj.department];
                }
            }];
            
            block(YES);
        }
        [HUD removeFromSuperview];
    }
     ];
    [[DDSearch instance] searchContent:searchText completion:^(NSArray *result, NSError *error) {
        self.keyString=searchText;
        if ([result count] >0) {
            [self.searchResult removeAllObjects];
            [self.groups removeAllObjects];
            [result enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isKindOfClass:[DDUserEntity class]]) {
                    [self.searchResult addObject:obj];
                }else if ([obj isKindOfClass:[GroupEntity class]])
                {
                    [self.groups addObject:obj];
                }
             
            }];
           block(YES);
        }
        [HUD removeFromSuperview];
    }];
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{

    [self.searchResult removeAllObjects];
    [self.groups removeAllObjects];
    [self.department removeAllObjects];
    [self reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.searchResult count];
    }else if(section == 1)
    {
        return [self.groups count];
    }else
    {
        return [self.department count];
    }
    
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"contactsCell";
    DDContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier ];
    if (cell == nil) {
        cell = [[DDContactsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    DDUserEntity *user=nil;
    if (indexPath.section == 0) {
        user = [self.searchResult objectAtIndex:indexPath.row];
        [cell setCellContent:[user getAvatarUrl] Name:user.nick Cname:@""];
    }else if(indexPath.section == 1)
    {
        GroupEntity *group = [self.groups objectAtIndex:indexPath.row];
        [cell setCellContent:group.avatar Name:group.name Cname:@""];
    }else
    {
      NSString *string = [self.department objectAtIndex:indexPath.row];
        [cell setCellContent:[user getAvatarUrl] Name:string Cname:@""];
    }
    
    
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [self.searchResult count]?@"联系人":@"";
    } else if(section == 1){
        return [self.groups count]?@"群组":@"";
    }else{
        return [self.department count ]?@"部门":@"";
    }
    
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        DDUserEntity *user;
        user = self.searchResult[indexPath.row];
        PublicProfileViewControll *public = [PublicProfileViewControll new];
        public.user=user;
        [self.viewController.navigationController pushViewController:public animated:YES];
  
        return;
        
    }else if(indexPath.section == 1)
    {
        GroupEntity *group = [self.groups objectAtIndex:indexPath.row];
        SessionEntity *session;
        if (![[SessionModule sharedInstance] getSessionById:group.objID]) {
            session = [[SessionEntity alloc] initWithSessionID:group.objID SessionName:group.name type:SessionTypeSessionTypeGroup];
        }else{
            session = [[SessionModule sharedInstance] getSessionById:group.objID];
        }
        
        [[ChattingMainViewController shareInstance] showChattingContentForSession:session];
        [self.viewController.navigationController  pushViewController:[ChattingMainViewController shareInstance] animated:YES];
    }else
    {
        NSString *string = [self.department objectAtIndex:indexPath.row];
        ContactsViewController *contact = [ContactsViewController new];
        contact.sectionTitle=string;
        contact.isSearchResult=YES;
        [self.viewController.navigationController  pushViewController:contact animated:YES];

    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
   
}
/*
#pragma mark - Navigation

 In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     Get the new view controller using [segue destinationViewController].
     Pass the selected object to the new view controller.
}
*/

@end
