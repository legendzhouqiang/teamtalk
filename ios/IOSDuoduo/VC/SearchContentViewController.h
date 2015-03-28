//
//  SearchContentViewController.h
//  TeamTalk
//
//  Created by Michael Scofield on 2014-10-20.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchContentViewController : UITableView<UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource>
-(void)searchTextDidChanged:(NSString *)searchText Block:(void(^)(bool done)) block;
@property(strong)UIViewController *viewController;
@end
