//
//  DDChatImagePreviewViewController.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-06-11.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "DDChatImagePreviewViewController.h"
@interface DDChatImagePreviewViewController ()
@property(nonatomic,strong)MWPhotoBrowser *browser ;
@end

@implementation DDChatImagePreviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title=@"预览";
    self.view.backgroundColor=[UIColor whiteColor];
    self.browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    self.browser.displayActionButton = NO;
    self.browser.displayNavArrows = NO;
    self.browser.wantsFullScreenLayout = YES;
    [self.browser setHidesBottomBarWhenPushed:YES];
    self.browser.zoomPhotosToFill = YES;
    [self.browser setCurrentPhotoIndex:0];
    [self.view addSubview:self.browser.view];
    [self.navigationController.navigationBar setHidden:YES];
    UILongPressGestureRecognizer * longPressGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressToDo:)];
    [self.browser.view addGestureRecognizer:longPressGr];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setShowOrHiddenNv)];
    tap.numberOfTouchesRequired = 1;
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    // Do any additional setup after loading the view.
}
-(void)setShowOrHiddenNv
{
    [self.navigationController.navigationBar setHidden:![self.navigationController.navigationBar isHidden]];
}
-(void)longPressToDo:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan){
        UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                          initWithTitle:nil
                                          delegate:self
                                          cancelButtonTitle:@"取消"
                                          destructiveButtonTitle:@"保存图片"
                                          otherButtonTitles:nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        [actionSheet showInView:self.view];
        
    }
   
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self saveImage];
    }


}
-(void)saveImage
{
    MWPhoto *curImage = [self.photos objectAtIndex:self.browser.currentIndex];
    UIImageWriteToSavedPhotosAlbum(curImage.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}
- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    
        if(error != NULL){
            [alert showError:self title:nil subTitle:@"保存图片失败" closeButtonTitle:nil duration:1.0f];
    
        }else{
            [alert showSuccess:self title:nil subTitle:@"保存图片成功" closeButtonTitle:nil duration:1.0f];
    
    }
    
}
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser{
    
    return [self.photos count];
}
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index{
    
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
