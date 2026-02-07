#import <UIKit/UIKit.h>
#import "FaceRecognition.h"
#import "CameraManager.h"
#import "UnlockManager.h"

static CameraManager *cameraManager;
static FaceRecognition *faceRecognition;
static UnlockManager *unlockManager;

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    // 初始化管理器
    cameraManager = [[CameraManager alloc] init];
    faceRecognition = [[FaceRecognition alloc] init];
    unlockManager = [[UnlockManager alloc] init];
    
    // 设置代理
    [cameraManager setDelegate:faceRecognition];
    [faceRecognition setDelegate:unlockManager];
    
    // 启动相机
    [cameraManager startCamera];
}

- (void)applicationWillResignActive:(id)application {
    %orig;
    [cameraManager stopCamera];
}

- (void)applicationDidBecomeActive:(id)application {
    %orig;
    [cameraManager startCamera];
}

%end
