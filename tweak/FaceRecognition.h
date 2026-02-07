#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraManager.h"

@protocol FaceRecognitionDelegate <NSObject>
- (void)faceRecognitionDidRecognizeFace:(BOOL)recognized withConfidence:(CGFloat)confidence;
@end

@interface FaceRecognition : NSObject <CameraManagerDelegate>

@property (nonatomic, weak) id<FaceRecognitionDelegate> delegate;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)registerFace:(UIImage *)faceImage withName:(NSString *)name;
- (void)unregisterFaceWithName:(NSString *)name;
- (NSArray *)registeredFaces;

@end
