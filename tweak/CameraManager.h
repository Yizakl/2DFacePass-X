#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraManagerDelegate <NSObject>
- (void)cameraDidCaptureFrame:(CMSampleBufferRef)sampleBuffer;
@end

@interface CameraManager : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id<CameraManagerDelegate> delegate;

- (void)startCamera;
- (void)stopCamera;
- (BOOL)isCameraRunning;

@end
