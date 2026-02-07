#import <UIKit/UIKit.h>

@interface FaceDatabase : NSObject

- (instancetype)init;
- (void)addFace:(UIImage *)faceImage;
- (void)addFaceToDenyList:(UIImage *)faceImage;
- (BOOL)isFaceRecognized:(UIImage *)faceImage;
- (void)saveDatabase;
- (void)loadDatabase;

@end
