#import <Foundation/Foundation.h>

@protocol UnlockManagerDelegate <NSObject>
- (void)unlockDidSucceed;
- (void)unlockDidFail;
@end

@interface UnlockManager : NSObject

@property (nonatomic, weak) id<UnlockManagerDelegate> delegate;

- (void)handleFaceRecognitionResult:(BOOL)recognized withConfidence:(CGFloat)confidence;
- (void)performUnlock;
- (BOOL)isDeviceLocked;

@end
