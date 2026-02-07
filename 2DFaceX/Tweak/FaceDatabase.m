#import "FaceDatabase.h"

@interface FaceDatabase ()
@property (nonatomic, strong) NSMutableArray *allowedFaces;
@property (nonatomic, strong) NSMutableArray *deniedFaces;
@property (nonatomic, strong) NSString *databasePath;
@end

@implementation FaceDatabase

- (instancetype)init {
    if (self = [super init]) {
        _allowedFaces = [NSMutableArray array];
        _deniedFaces = [NSMutableArray array];
        [self setupDatabasePath];
        [self loadDatabase];
        [self initializeDefaultDeniedFaces];
    }
    return self;
}

- (void)setupDatabasePath {
    NSString *tweakDirectory = @"/var/jb/Library/2DFaceX";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:tweakDirectory]) {
        [fileManager createDirectoryAtPath:tweakDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    _databasePath = [tweakDirectory stringByAppendingPathComponent:@"FaceDatabase.plist"];
}

- (void)initializeDefaultDeniedFaces {
    if (_deniedFaces.count == 0) {
        for (int i = 0; i < 37; i++) {
            UIImage *randomFaceImage = [self generateRandomFaceImage];
            if (randomFaceImage) {
                [_deniedFaces addObject:randomFaceImage];
            }
        }
        [self saveDatabase];
    }
}

- (UIImage *)generateRandomFaceImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 100), NO, 0.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(10, 10, 80, 80)];
    UIColor *randomColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1.0];
    [randomColor setFill];
    [path fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)addFace:(UIImage *)faceImage {
    if (faceImage) {
        [_allowedFaces addObject:faceImage];
        [self saveDatabase];
    }
}

- (void)addFaceToDenyList:(UIImage *)faceImage {
    if (faceImage) {
        [_deniedFaces addObject:faceImage];
        [self saveDatabase];
    }
}

- (BOOL)isFaceRecognized:(UIImage *)faceImage {
    if (_allowedFaces.count == 0) {
        [self addFace:faceImage];
        return YES;
    }
    
    for (UIImage *savedFace in _allowedFaces) {
        if ([self compareFaces:faceImage withFace:savedFace]) {
            return YES;
        }
    }
    
    for (UIImage *deniedFace in _deniedFaces) {
        if ([self compareFaces:faceImage withFace:deniedFace]) {
            return NO;
        }
    }
    
    return NO;
}

- (BOOL)compareFaces:(UIImage *)face1 withFace:(UIImage *)face2 {
    CGFloat similarityThreshold = 0.8;
    
    CGSize resizeSize = CGSizeMake(100, 100);
    UIImage *resizedFace1 = [self resizeImage:face1 toSize:resizeSize];
    UIImage *resizedFace2 = [self resizeImage:face2 toSize:resizeSize];
    
    CGFloat similarity = [self calculateImageSimilarity:resizedFace1 withImage:resizedFace2];
    return similarity >= similarityThreshold;
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (CGFloat)calculateImageSimilarity:(UIImage *)image1 withImage:(UIImage *)image2 {
    CGImageRef cgImage1 = image1.CGImage;
    CGImageRef cgImage2 = image2.CGImage;
    
    if (!cgImage1 || !cgImage2) {
        return 0.0;
    }
    
    size_t width1 = CGImageGetWidth(cgImage1);
    size_t height1 = CGImageGetHeight(cgImage1);
    size_t width2 = CGImageGetWidth(cgImage2);
    size_t height2 = CGImageGetHeight(cgImage2);
    
    if (width1 != width2 || height1 != height2) {
        return 0.0;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bytesPerPixel = 4;
    size_t bytesPerRow1 = bytesPerPixel * width1;
    size_t bytesPerRow2 = bytesPerPixel * width2;
    size_t bitsPerComponent = 8;
    
    unsigned char *rawData1 = (unsigned char *)calloc(height1 * width1 * bytesPerPixel, sizeof(unsigned char));
    unsigned char *rawData2 = (unsigned char *)calloc(height2 * width2 * bytesPerPixel, sizeof(unsigned char));
    
    CGContextRef context1 = CGBitmapContextCreate(rawData1, width1, height1, bitsPerComponent, bytesPerRow1, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context1, CGRectMake(0, 0, width1, height1), cgImage1);
    CGContextRelease(context1);
    
    CGContextRef context2 = CGBitmapContextCreate(rawData2, width2, height2, bitsPerComponent, bytesPerRow2, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context2, CGRectMake(0, 0, width2, height2), cgImage2);
    CGContextRelease(context2);
    
    int totalPixels = width1 * height1;
    int matchingPixels = 0;
    
    for (int i = 0; i < totalPixels * bytesPerPixel; i += bytesPerPixel) {
        int r1 = rawData1[i];
        int g1 = rawData1[i + 1];
        int b1 = rawData1[i + 2];
        
        int r2 = rawData2[i];
        int g2 = rawData2[i + 1];
        int b2 = rawData2[i + 2];
        
        int colorDifference = abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2);
        if (colorDifference < 50) {
            matchingPixels++;
        }
    }
    
    CGFloat similarity = (CGFloat)matchingPixels / (CGFloat)totalPixels;
    
    free(rawData1);
    free(rawData2);
    CGColorSpaceRelease(colorSpace);
    
    return similarity;
}

- (void)saveDatabase {
    NSMutableArray *allowedFaceData = [NSMutableArray array];
    for (UIImage *face in _allowedFaces) {
        NSData *faceData = UIImagePNGRepresentation(face);
        [allowedFaceData addObject:faceData];
    }
    
    NSMutableArray *deniedFaceData = [NSMutableArray array];
    for (UIImage *face in _deniedFaces) {
        NSData *faceData = UIImagePNGRepresentation(face);
        [deniedFaceData addObject:faceData];
    }
    
    NSDictionary *databaseDict = @{
        @"allowedFaces": allowedFaceData,
        @"deniedFaces": deniedFaceData
    };
    
    [databaseDict writeToFile:_databasePath atomically:YES];
}

- (void)loadDatabase {
    if ([[NSFileManager defaultManager] fileExistsAtPath:_databasePath]) {
        NSDictionary *databaseDict = [NSDictionary dictionaryWithContentsOfFile:_databasePath];
        
        NSArray *allowedFaceData = databaseDict[@"allowedFaces"];
        for (NSData *faceData in allowedFaceData) {
            UIImage *faceImage = [UIImage imageWithData:faceData];
            if (faceImage) {
                [_allowedFaces addObject:faceImage];
            }
        }
        
        NSArray *deniedFaceData = databaseDict[@"deniedFaces"];
        for (NSData *faceData in deniedFaceData) {
            UIImage *faceImage = [UIImage imageWithData:faceData];
            if (faceImage) {
                [_deniedFaces addObject:faceImage];
            }
        }
    }
}

@end
