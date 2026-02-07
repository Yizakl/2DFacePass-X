#import <Vision/Vision.h>
#import "FaceRecognizer.h"
#import "FaceDatabase.h"

@interface FaceRecognizer ()
@property (nonatomic, strong) FaceDatabase *faceDatabase;
@property (nonatomic, strong) VNDetectFaceLandmarksRequest *faceDetectionRequest;
@end

@implementation FaceRecognizer

- (instancetype)init {
    if (self = [super init]) {
        _faceDatabase = [[FaceDatabase alloc] init];
        [self setupFaceDetection];
    }
    return self;
}

- (void)setupFaceDetection {
    _faceDetectionRequest = [[VNDetectFaceLandmarksRequest alloc] init];
}

- (BOOL)recognizeFace:(UIImage *)faceImage {
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:faceImage.CGImage options:@{}];
    
    NSError *error = nil;
    [requestHandler performRequests:@[_faceDetectionRequest] error:&error];
    
    if (error) {
        NSLog(@"Face detection error: %@", error);
        return NO;
    }
    
    NSArray *faceObservations = _faceDetectionRequest.results;
    if (faceObservations.count == 0) {
        NSLog(@"No face detected");
        return NO;
    }
    
    VNFaceObservation *faceObservation = faceObservations.firstObject;
    return [self processFaceObservation:faceObservation fromImage:faceImage];
}

- (BOOL)processFaceObservation:(VNFaceObservation *)faceObservation fromImage:(UIImage *)image {
    CGRect faceBounds = faceObservation.boundingBox;
    CGSize imageSize = image.size;
    CGRect faceRect = CGRectMake(
        faceBounds.origin.x * imageSize.width,
        (1.0 - faceBounds.origin.y - faceBounds.size.height) * imageSize.height,
        faceBounds.size.width * imageSize.width,
        faceBounds.size.height * imageSize.height
    );
    
    CGImageRef faceCGImage = CGImageCreateWithImageInRect(image.CGImage, faceRect);
    UIImage *faceImage = [UIImage imageWithCGImage:faceCGImage];
    CGImageRelease(faceCGImage);
    
    return [_faceDatabase isFaceRecognized:faceImage];
}

- (void)addFaceToDatabase:(UIImage *)faceImage {
    [_faceDatabase addFace:faceImage];
}

- (void)addFaceToDenyList:(UIImage *)faceImage {
    [_faceDatabase addFaceToDenyList:faceImage];
}

@end
