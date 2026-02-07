#import <UIKit/UIKit.h>

@interface FaceRecognizer : NSObject

- (instancetype)init;
- (BOOL)recognizeFace:(UIImage *)faceImage;
- (void)addFaceToDatabase:(UIImage *)faceImage;
- (void)addFaceToDenyList:(UIImage *)faceImage;

@end
