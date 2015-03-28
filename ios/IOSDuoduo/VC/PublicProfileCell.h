//
//  PublicProfileCell.h
//  TeamTalk
//
//  Created by scorpio on 14/12/18.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PublicProfileCell : UITableViewCell

@property (nonatomic,retain)UILabel* descLabel;
@property (nonatomic,retain)UILabel* detailLabel;
@property (nonatomic,retain)UIImageView* phone;

- (void)setDesc:(NSString *)desc detail:(NSString *)detail;
- (void)hidePhone:(BOOL)hide;

@end
