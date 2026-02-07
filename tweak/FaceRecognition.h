#import <Foundation/Foundation.h>

@protocol FaceRecognitionDelegate <NSObject>
- (void)faceRecognitionDidRecognizeFace:(BOOL)recognized withConfidence:(CGFloat)confidence;
@end

@interface FaceRecognition : NSObject

@property (nonatomic, weak) id<FaceRecognitionDelegate> delegate;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)registerFace:(UIImage *)faceImage withName:(NSString *)name;
- (void)unregisterFaceWithName:(NSString *)name;
- (NSArray *)registeredFaces;

@end
