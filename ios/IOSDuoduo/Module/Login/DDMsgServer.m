//
//  DDMsgServer.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-5.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDMsgServer.h"
//#import "LoginEntity.h"
#import "DDTcpClientManager.h"
#import "LoginAPI.h"
//#import "LoginEntity.h"
static int const timeOutTimeInterval = 10;

typedef void(^CheckSuccess)(id object);

@interface DDMsgServer(PrivateAPI)

- (void)n_receiveLoginMsgServerNotification:(NSNotification*)notification;
- (void)n_receiveLoginLoginServerNotification:(NSNotification*)notification;

@end

@implementation DDMsgServer
{
    CheckSuccess _success;
    Failure _failure;
    
    BOOL _connecting;
    NSUInteger _connectTimes;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _connecting = NO;
        _connectTimes = 0;
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveLoginMsgServerNotification:) name:notificationLoginMsgServerSuccess object:nil];
    }
    return self;
}

-(void)checkUserID:(NSString*)userID Pwd:(NSString *)password token:(NSString*)token success:(void(^)(id object))success failure:(void(^)(id object))failure
{
    
    if (!_connecting)
    {
        
        NSNumber* clientType = @(17);
        NSString *clientVersion = [NSString stringWithFormat:@"MAC/%@-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        NSArray* parameter = @[userID,password,clientVersion,clientType];
        
        LoginAPI* api = [[LoginAPI alloc] init];
        [api requestWithObject:parameter Completion:^(id response, NSError *error) {
            if (!error)
            {
                if (response)
                {
                    NSString *resultString =response[@"resultString"];
                    if (resultString == nil) {
                         success(response);
                    }
                }else{
                    failure(error);
                }
                
            }
            else
            {
                DDLog(@"error:%@",[error domain]);
                failure(error);
            }
        }];
    }
}

@end
