//
//  FinderViewController.m
//  TeamTalk
//
//  Created by 独嘉 on 14-10-22.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "FinderViewController.h"
#import "OpenSourcePRViewController.h"
#import "WifiViewController.h"
#import "std.h"
#import "TTHttpsRequest.h"
#import "AFHTTPRequestOperationManager.h"
#import "ScanQRCodePage.h"
@interface FinderViewController ()
@property(strong)NSURLConnection *connection;
@property(strong)NSMutableDictionary *sources;
@property(strong)NSMutableArray *sortList;
@end

@implementation FinderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发现";
    [self.tableView setScrollEnabled:NO];
    
    [self setExtraCellLineHidden:_tableView];
     self.sources = [NSMutableDictionary new];
     self.sortList = [NSMutableArray new];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:TheRuntime.discoverUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSArray *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        if (responseDictionary) {
            [responseDictionary enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                NSString *itemName =obj[@"itemName"];
                NSString *priority =[NSString stringWithFormat:@"%d",[obj[@"itemPriority"] integerValue]];
                [self.sources setObject:obj[@"itemUrl"] forKey:[NSString stringWithFormat:@"%@_%@",priority,itemName]];
                [self.sortList addObject:obj[@"itemPriority"]];

            }];
            
            NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO];//yes升序排列，no,降序排列
            [self.sortList removeAllObjects];
            self.sortList= [NSMutableArray arrayWithArray:[self.sortList sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sd1, nil]]];
            [self.tableView reloadData];

        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

-(void)setExtraCellLineHidden: (UITableView *)tableView
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [tableView setTableFooterView:view];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self allKeys] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"FinderCellIdentifier";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = RGB(244, 245, 246);
    NSInteger row = [indexPath row];
    NSString *title = [[self allKeys] objectAtIndex:row];
    NSArray *array = [title componentsSeparatedByString:@"_"];
    [cell.textLabel setText:array[1]];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = [indexPath row];
    NSString *title = [[self allKeys] objectAtIndex:row];
    NSString *urlString = [self.sources objectForKey:title];
    OpenSourcePRViewController* prViewController = [[OpenSourcePRViewController alloc] init];
    prViewController.urlString=urlString;
    [self.navigationController pushViewController:prViewController animated:YES];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}
-(NSArray*)allKeys{
    NSArray *departmentIndexes =[[self.sources allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSArray *array = [obj1 componentsSeparatedByString:@"_"];
                NSInteger tmp1 = [array[0] integerValue];
                NSArray *array2 = [obj2 componentsSeparatedByString:@"_"];
                NSInteger tmp2 = [array2[0] integerValue];
                return [@(tmp1) compare:@(tmp2)];}];
            return  departmentIndexes;

}


@end
