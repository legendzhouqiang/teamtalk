//
//  DDDDChatUtilityViewController.h
//  IOSDuoduo
//
//  Created by 东邪 on 14-5-23.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQGridViewController.h"
#import "AQGridView.h"
@interface ChatUtilityViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(nonatomic,strong) UIImagePickerController *imagePicker;
@end
