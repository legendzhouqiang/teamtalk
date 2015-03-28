//
//  DDDDChatUtilityViewController.m
//  IOSDuoduo
//
//  Created by 东邪 on 14-5-23.
//  Copyright (c) 2014年 dujia. All rights reserved.
//
static NSString * const ItemCellIdentifier = @"ItemCellIdentifier";
#import "ChatUtilityViewController.h"
#import "AQGridView.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "ChattingMainViewController.h"
#import "AlbumViewController.h"
#import "DDSendPhotoMessageAPI.h"
#import "ChattingMainViewController.h"
#import "DDMessageSendManager.h"
#import "DDDatabaseUtil.h"
#import "SDImageCache.h"
#import "std.h"
#import "DDAppDelegate.h"
#import "PhotosCache.h"
@interface ChatUtilityViewController ()
@property(nonatomic,strong)NSArray *itemsArray;
@end

@implementation ChatUtilityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //self.animation = AnimationSlideVertical;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor=RGB(224, 224, 224);
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FULL_WIDTH, 0.5)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self.view addSubview:line];
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    UIButton *takePictureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [takePictureBtn setBackgroundImage:[UIImage imageNamed:@"dd_take-photo"] forState:UIControlStateNormal];
    takePictureBtn.frame=CGRectMake(self.view.center.x-85, 60, 65, 65);
    [takePictureBtn setClipsToBounds:YES];
    [takePictureBtn.layer setCornerRadius:65/2];
    [takePictureBtn addTarget:self action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takePictureBtn];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(takePictureBtn.frame.origin.x, takePictureBtn.frame.origin.y+takePictureBtn.frame.size.height+12, takePictureBtn.frame.size.width, 13)];
    [label setText:@"拍照"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:13]];
    [self.view addSubview:label];
    
    
    UIButton *choosePictureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [choosePictureBtn setBackgroundImage:[UIImage imageNamed:@"dd_album"] forState:UIControlStateNormal];
    choosePictureBtn.frame=CGRectMake(takePictureBtn.frame.origin.x+55+60, 60, 65, 65);
    [choosePictureBtn setClipsToBounds:YES];
    [choosePictureBtn.layer setCornerRadius:65/2];
    [choosePictureBtn addTarget:self action:@selector(choosePicture:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:choosePictureBtn];
    
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(choosePictureBtn.frame.origin.x, choosePictureBtn.frame.origin.y+choosePictureBtn.frame.size.height+12, choosePictureBtn.frame.size.width, 13)];
    [label1 setText:@"相册"];
    [label1 setTextAlignment:NSTextAlignmentCenter];
    [label1 setFont:[UIFont systemFontOfSize:13]];
    [self.view addSubview:label1];
}
-(IBAction)choosePicture:(id)sender
{
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController pushViewController:[AlbumViewController new] animated:YES];
}
-(IBAction)takePicture:(id)sender
{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            {
                self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
            self.imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            self.imagePicker.wantsFullScreenLayout=YES;
            if (self.imagePicker ) {
                 [[ChattingMainViewController shareInstance].navigationController presentViewController:self.imagePicker animated:NO completion:nil];
            }else{
                self.imagePicker = [[UIImagePickerController alloc] init];
                self.imagePicker.delegate = self;
                self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                self.imagePicker.wantsFullScreenLayout=YES;
                [[ChattingMainViewController shareInstance].navigationController presentViewController:self.imagePicker animated:NO completion:nil];
            }
           
        });
}
- (void) viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
   
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    
}
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker
{
    
    [picker dismissViewControllerAnimated:YES completion:nil];
      self.imagePicker=nil;
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:( NSString *)kUTTypeImage]){
  
        __block UIImage *theImage = nil;
        if ([picker allowsEditing]){
            theImage = [info objectForKey:UIImagePickerControllerEditedImage];
        } else {
            theImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            
        }
        UIImage *image = [self scaleImage:theImage toScale:0.3];
        NSData *imageData = UIImageJPEGRepresentation(image, (CGFloat)1.0);
        UIImage * m_selectImage = [UIImage imageWithData:imageData];
            __block Photo *photo = [Photo new];
            NSString *keyName = [[PhotosCache sharedPhotoCache] getKeyName];
            photo.localPath=keyName;
        [picker dismissViewControllerAnimated:NO completion:nil];
        self.imagePicker=nil;
            [[ChattingMainViewController shareInstance] sendImageMessage:photo Image:m_selectImage];
    }

}
#pragma mark -
#pragma mark 等比縮放image
- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width*scaleSize, image.size.height*scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
