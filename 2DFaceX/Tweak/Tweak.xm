#import <UIKit/UIKit.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <AVFoundation/AVFoundation.h>
#import "FaceRecognizer.h"

@interface SBLockScreenViewController : UIViewController
@end

@interface SBLockScreenPasscodeViewController : UIViewController
- (void)performUnlockAnimationForUIUnlockFromSource:(int)source;
@end

static SBLockScreenViewController *_lockScreenViewController = nil;
static SBLockScreenPasscodeViewController *_passcodeViewController = nil;
static FaceRecognizer *_faceRecognizer = nil;
static AVCaptureSession *_captureSession = nil;
static AVCaptureVideoPreviewLayer *_previewLayer = nil;
static UIView *_cameraView = nil;
static UILabel *_statusLabel = nil;
static dispatch_once_t _onceToken;

static void (*originalViewDidAppear)(id, SEL, BOOL);
static void replacedViewDidAppear(id self, SEL _cmd, BOOL animated) {
    originalViewDidAppear(self, _cmd, animated);
    
    if ([self isKindOfClass:NSClassFromString(@"SBLockScreenViewController")]) {
        _lockScreenViewController = (SBLockScreenViewController *)self;
        [self setupFaceRecognition];
    }
}

- (void)setupFaceRecognition {
    dispatch_once(&_onceToken, ^{  
        _faceRecognizer = [[FaceRecognizer alloc] init];
        [self setupCamera];
        [self startFaceRecognition];
    });
}

- (void)setupCamera {
    _captureSession = [[AVCaptureSession alloc] init];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (input) {
        [_captureSession addInput:input];
        
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
        [_captureSession addOutput:output];
        
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        _cameraView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _cameraView.center = _lockScreenViewController.view.center;
        _cameraView.layer.cornerRadius = 100;
        _cameraView.clipsToBounds = YES;
        [_cameraView.layer addSublayer:_previewLayer];
        
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _cameraView.frame.origin.y + 220, 320, 40)];
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.textColor = [UIColor whiteColor];
        _statusLabel.text = @"Scanning...";
        
        [_lockScreenViewController.view addSubview:_cameraView];
        [_lockScreenViewController.view addSubview:_statusLabel];
        
        [_captureSession startRunning];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    UIImage *image = [self imageFromPixelBuffer:pixelBuffer];
    
    BOOL recognized = [_faceRecognizer recognizeFace:image];
    
    if (recognized) {
        dispatch_async(dispatch_get_main_queue(), ^{  
            [self unlockDevice];
        });
    }
}

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

- (void)startFaceRecognition {
    _statusLabel.text = @"Scanning face...";
}

- (void)unlockDevice {
    [_captureSession stopRunning];
    [_cameraView removeFromSuperview];
    [_statusLabel removeFromSuperview];
    
    _passcodeViewController = (SBLockScreenPasscodeViewController *)[_lockScreenViewController valueForKey:@"_passcodeViewController"];
    if (_passcodeViewController) {
        [_passcodeViewController performUnlockAnimationForUIUnlockFromSource:0];
    }
}

%hook SBLockScreenViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    _lockScreenViewController = self;
    [self setupFaceRecognition];
}

%end

%ctor {
    Class cls = NSClassFromString(@"SBLockScreenViewController");
    if (cls) {
        MSHookMessageEx(cls, @selector(viewDidAppear:), (IMP)replacedViewDidAppear, (IMP *)&originalViewDidAppear);
    }
}
