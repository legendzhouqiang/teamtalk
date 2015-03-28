//
//  RootViewController.m
//  TeamTalk
//
//  Created by Michael Scofield on 2015-01-28.
//  Copyright (c) 2015 Michael Hu. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame=CGRectMake(0, 0, 60, 40);
    UIImage* image = [UIImage imageNamed:@"top_back"];
    [back setImage:image forState:UIControlStateNormal];
    [back setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [back setTitle:@"返回" forState:UIControlStateNormal];
    [back setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [back addTarget:self action:@selector(p_popViewController) forControlEvents:UIControlEventTouchUpInside];
     UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.backBarButtonItem = backButton;
    // Do any additional setup after loading the view.
}
-(void)p_popViewController
{
    [self.navigationController popViewControllerAnimated:YES];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
