#import "UnlockManager.h"
#import <UIKit/UIKit.h>

@interface UnlockManager ()

@property (nonatomic, assign) BOOL isUnlocking;
@property (nonatomic, strong) dispatch_queue_t unlockQueue;

@end

@implementation UnlockManager

- (instancetype)init {
    if (self = [super init]) {
        self.isUnlocking = NO;
        self.unlockQueue = dispatch_queue_create("com.example.unlockManager.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)handleFaceRecognitionResult:(BOOL)recognized withConfidence:(CGFloat)confidence {
    dispatch_async(self.unlockQueue, ^{        if (self.isUnlocking) return;
        
        if (recognized && confidence > 0.7) {
            // 面部识别成功，执行解锁
            [self performUnlock];
        } else {
            // 面部识别失败
            if (self.delegate && [self.delegate respondsToSelector:@selector(unlockDidFail)]) {
                dispatch_async(dispatch_get_main_queue(), ^{                    [self.delegate unlockDidFail];
                });
            }
        }
    });
}

- (void)performUnlock {
    self.isUnlocking = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{        // 检查设备是否锁定
        if ([self isDeviceLocked]) {
            // 执行解锁操作
            // 这里使用私有API来模拟解锁，实际应用中可能需要根据iOS版本和越狱环境进行调整
            
            // 方法1: 模拟用户点击解锁按钮
            UIApplication *app = [UIApplication sharedApplication];
            if (app) {
                // 发送解锁通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SpringBoardDidUnlockDevice" object:nil];
                
                // 尝试解锁SpringBoard
                Class SBUIControllerClass = NSClassFromString(@"SBUIController");
                if (SBUIControllerClass) {
                    id sbuiController = [SBUIControllerClass valueForKey:@"sharedInstance"];
                    if (sbuiController) {
                        SEL unlockMethod = NSSelectorFromString(@"unlockDevice");
                        if ([sbuiController respondsToSelector:unlockMethod]) {
                            [sbuiController performSelector:unlockMethod];
                        }
                    }
                }
            }
            
            NSLog(@"Unlock performed successfully");
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(unlockDidSucceed)]) {
                [self.delegate unlockDidSucceed];
            }
        } else {
            NSLog(@"Device is not locked");
        }
        
        self.isUnlocking = NO;
    });
}

- (BOOL)isDeviceLocked {
    // 检查设备是否锁定
    // 这里使用私有API来检查锁定状态，实际应用中可能需要根据iOS版本和越狱环境进行调整
    
    Class SBLockScreenManagerClass = NSClassFromString(@"SBLockScreenManager");
    if (SBLockScreenManagerClass) {
        id lockScreenManager = [SBLockScreenManagerClass valueForKey:@"sharedInstance"];
        if (lockScreenManager) {
            SEL isLockedMethod = NSSelectorFromString(@"isLocked");
            if ([lockScreenManager respondsToSelector:isLockedMethod]) {
                return [[lockScreenManager performSelector:isLockedMethod] boolValue];
            }
        }
    }
    
    // 备用方法：检查是否存在锁屏界面
    UIApplication *app = [UIApplication sharedApplication];
    if (app) {
        UIWindow *keyWindow = app.keyWindow;
        if (keyWindow) {
            for (UIView *view in keyWindow.subviews) {
                if ([view.className containsString:@"LockScreen"] || [view.className containsString:@"Passcode"]) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

@end
