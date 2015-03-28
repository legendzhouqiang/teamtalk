//
//  GroupAvatarImage.h
//  TeamTalk
//
//  Created by Michael Scofield on 2014-09-25.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GroupEntity;
@interface GroupAvatarImage : UIImageView
-(GroupAvatarImage *)getGroupImage:(GroupEntity *)group Block:(void(^)(UIImage *))block;
@end
