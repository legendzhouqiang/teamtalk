//
//  WifiViewController.m
//  TeamTalk
//
//  Created by 独嘉 on 14-10-22.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "WifiViewController.h"

@interface WifiViewController ()

@end

@implementation WifiViewController

{
    UIWebView* _webView;
    UIActivityIndicatorView* _activityIndicatorView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"街利贷";
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    NSURL* url = [NSURL URLWithString:@"https://f.mogujie.com/p2p/home/investment"];
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:urlRequest];
    [_webView setDelegate:self];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_activityIndicatorView stopAnimating];
}


@end
