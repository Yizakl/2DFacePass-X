#import <Foundation/Foundation.h>
#import "FaceRecognition.h"

@protocol UnlockManagerDelegate <NSObject>
- (void)unlockDidSucceed;
- (void)unlockDidFail;
@end

@interface UnlockManager : NSObject <FaceRecognitionDelegate>

@property (nonatomic, weak) id<UnlockManagerDelegate> delegate;

- (void)handleFaceRecognitionResult:(BOOL)recognized withConfidence:(CGFloat)confidence;
- (void)performUnlock;
- (BOOL)isDeviceLocked;

@end
