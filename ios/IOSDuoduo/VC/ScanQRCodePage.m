//
//  ViewController.m
//  CashBank
//
//  Created by Michael Scofield on 2014-10-23.
//  Copyright (c) 2014 Michael. All rights reserved.
//

#import "ScanQRCodePage.h"

@interface ScanQRCodePage ()

@end

@implementation ScanQRCodePage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"扫一扫";
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 100, 300, 300)];
    imageView.image = [UIImage imageNamed:@"pick_bg"];
    [self.view addSubview:imageView];
    
    upOrdown = NO;
    num =0;
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(50, 110, 220, 2)];
    _line.image = [UIImage imageNamed:@"line.png"];
    [self.view addSubview:_line];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
     [self setupCamera];
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)animation1
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(50, 110+2*num, 220, 2);
        if (2*num == 280) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(50, 110+2*num, 220, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [timer invalidate];
    [self.tabBarController.tabBar setHidden:NO];
}
-(void)viewWillAppear:(BOOL)animated
{
    [_session startRunning];
    [self.tabBarController.tabBar setHidden:YES];
    
}
- (void)setupCamera
{
    // Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Session
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame =CGRectMake(0, 0, FULL_WIDTH, FULL_HEIGHT);
    [self.view.layer insertSublayer:_preview atIndex:0];
    // Start
    [_session startRunning];
}
#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    NSString *stringValue;
    
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
    
    [_session stopRunning];
   
    [timer invalidate];
    [self showResult:stringValue];
    
}
-(void)showScanResult:(NSString *)scanResult
{
    SCLAlertView *alert = [SCLAlertView new];
    [alert addButton:@"复制" actionBlock:^{
        UIPasteboard *pboard = [UIPasteboard generalPasteboard];
        pboard.string = scanResult;
        [_session startRunning];
    }];
    [alert addButton:@"打开" actionBlock:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:scanResult]];
        [_session startRunning];
    }];
    [alert addButton:@"再来" actionBlock:^{
        [_session startRunning];
    }];
    
    [alert showInfo:self title:@"扫描结果" subTitle:scanResult closeButtonTitle:nil duration:0];
}
-(NSString *)showResult:(NSString *)codeSources
{
    [self showScanResult:codeSources];
    return nil;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)scanAgain:(id)sender
{
    [_session startRunning];
}
@end
