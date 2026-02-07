#import "FaceRecognition.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

@interface FaceRecognition () <CameraManagerDelegate>

@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) NSMutableDictionary *registeredFaces;
@property (nonatomic, strong) dispatch_queue_t processingQueue;

@end

@implementation FaceRecognition

- (instancetype)init {
    if (self = [super init]) {
        // 初始化面部检测器
        NSDictionary *options = @{
            CIDetectorAccuracy : CIDetectorAccuracyHigh,
            CIDetectorTracking : @YES
        };
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
        
        // 初始化已注册面部数据
        self.registeredFaces = [NSMutableDictionary dictionary];
        
        // 创建处理队列
        self.processingQueue = dispatch_queue_create("com.example.faceRecognition.processing", DISPATCH_QUEUE_SERIAL);
        
        // 加载已保存的面部数据
        [self loadRegisteredFaces];
    }
    return self;
}

#pragma mark - CameraManagerDelegate

- (void)cameraDidCaptureFrame:(CMSampleBufferRef)sampleBuffer {
    [self processSampleBuffer:sampleBuffer];
}

#pragma mark - Public Methods

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    dispatch_async(self.processingQueue, ^{        
        // 从sampleBuffer创建CIImage
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
        
        // 检测面部
        NSArray *faces = [self.faceDetector featuresInImage:ciImage];
        
        if (faces.count > 0) {
            // 获取第一个检测到的面部
            CIFaceFeature *faceFeature = [faces firstObject];
            
            // 检查面部大小，过滤过小的面部
            CGRect faceBounds = faceFeature.bounds;
            if (faceBounds.size.width < 50 || faceBounds.size.height < 50) {
                return; // 面部过小，可能是误检测
            }
            
            // 提取面部特征
            NSDictionary *faceFeatures = [self extractFaceFeatures:ciImage forFace:faceFeature];
            
            // 比对面部
            BOOL recognized = NO;
            CGFloat confidence = 0.0;
            
            if ([self.registeredFaces count] > 0) {
                recognized = [self compareFaceFeatures:faceFeatures confidence:&confidence];
            }
            
            // 通知代理
            if (self.delegate && [self.delegate respondsToSelector:@selector(faceRecognitionDidRecognizeFace:withConfidence:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{                    [self.delegate faceRecognitionDidRecognizeFace:recognized withConfidence:confidence];
                });
            }
        }
    });
}

- (void)registerFace:(UIImage *)faceImage withName:(NSString *)name {
    // 转换为CIImage
    CIImage *ciImage = [CIImage imageWithCGImage:faceImage.CGImage];
    
    // 检测面部
    NSArray *faces = [self.faceDetector featuresInImage:ciImage];
    
    if (faces.count > 0) {
        CIFaceFeature *faceFeature = [faces firstObject];
        
        // 提取面部特征
        NSDictionary *faceFeatures = [self extractFaceFeatures:ciImage forFace:faceFeature];
        
        // 保存面部特征
        [self.registeredFaces setObject:faceFeatures forKey:name];
        
        // 持久化存储
        [self saveRegisteredFaces];
        
        NSLog(@"Face registered successfully: %@", name);
    } else {
        NSLog(@"Error: No face detected in image");
    }
}

- (void)unregisterFaceWithName:(NSString *)name {
    [self.registeredFaces removeObjectForKey:name];
    [self saveRegisteredFaces];
    NSLog(@"Face unregistered: %@", name);
}

- (NSArray *)registeredFaces {
    return [self.registeredFaces allKeys];
}

#pragma mark - Private Methods

- (NSDictionary *)extractFaceFeatures:(CIImage *)ciImage forFace:(CIFaceFeature *)faceFeature {
    // 提取面部特征点
    NSMutableDictionary *features = [NSMutableDictionary dictionary];
    
    // 存储眼睛位置
    if (faceFeature.hasLeftEyePosition) {
        [features setObject:[NSValue valueWithCGPoint:faceFeature.leftEyePosition] forKey:@"leftEye"];
    }
    
    if (faceFeature.hasRightEyePosition) {
        [features setObject:[NSValue valueWithCGPoint:faceFeature.rightEyePosition] forKey:@"rightEye"];
    }
    
    // 存储嘴巴位置
    if (faceFeature.hasMouthPosition) {
        [features setObject:[NSValue valueWithCGPoint:faceFeature.mouthPosition] forKey:@"mouth"];
    }
    
    // 存储面部边界
    [features setObject:[NSValue valueWithCGRect:faceFeature.bounds] forKey:@"bounds"];
    
    // 计算面部中心点
    CGPoint faceCenter = CGPointMake(CGRectGetMidX(faceFeature.bounds), CGRectGetMidY(faceFeature.bounds));
    [features setObject:[NSValue valueWithCGPoint:faceCenter] forKey:@"center"];
    
    // 计算面部宽高比
    CGFloat faceAspectRatio = faceFeature.bounds.size.width / faceFeature.bounds.size.height;
    [features setObject:@(faceAspectRatio) forKey:@"aspectRatio"];
    
    return features;
}

- (BOOL)compareFaceFeatures:(NSDictionary *)faceFeatures confidence:(CGFloat *)confidence {
    if ([self.registeredFaces count] == 0) {
        *confidence = 0.0;
        return NO;
    }
    
    CGFloat highestConfidence = 0.0;
    
    for (NSString *name in self.registeredFaces) {
        NSDictionary *registeredFeatures = self.registeredFaces[name];
        CGFloat currentConfidence = [self calculateConfidenceBetween:faceFeatures and:registeredFeatures];
        
        if (currentConfidence > highestConfidence) {
            highestConfidence = currentConfidence;
        }
    }
    
    *confidence = highestConfidence;
    
    // 阈值判断
    return highestConfidence > 0.7;
}

- (CGFloat)calculateConfidenceBetween:(NSDictionary *)face1 and:(NSDictionary *)face2 {
    // 计算两个面部特征之间的相似度
    // 这里使用简单的几何距离计算，实际应用中可以使用更复杂的算法
    
    CGFloat totalDistance = 0.0;
    NSInteger featureCount = 0;
    
    // 比较眼睛位置
    if (face1[@"leftEye"] && face2[@"leftEye"] && face1[@"rightEye"] && face2[@"rightEye"]) {
        CGPoint leftEye1 = [face1[@"leftEye"] CGPointValue];
        CGPoint rightEye1 = [face1[@"rightEye"] CGPointValue];
        CGPoint leftEye2 = [face2[@"leftEye"] CGPointValue];
        CGPoint rightEye2 = [face2[@"rightEye"] CGPointValue];
        
        // 计算眼睛之间的距离比例
        CGFloat distance1 = sqrt(pow(rightEye1.x - leftEye1.x, 2) + pow(rightEye1.y - leftEye1.y, 2));
        CGFloat distance2 = sqrt(pow(rightEye2.x - leftEye2.x, 2) + pow(rightEye2.y - leftEye2.y, 2));
        
        if (distance1 > 0 && distance2 > 0) {
            CGFloat distanceRatio = MIN(distance1/distance2, distance2/distance1);
            totalDistance += distanceRatio;
            featureCount++;
        }
    }
    
    // 比较嘴巴位置
    if (face1[@"mouth"] && face2[@"mouth"] && face1[@"leftEye"] && face2[@"leftEye"]) {
        CGPoint mouth1 = [face1[@"mouth"] CGPointValue];
        CGPoint leftEye1 = [face1[@"leftEye"] CGPointValue];
        CGPoint mouth2 = [face2[@"mouth"] CGPointValue];
        CGPoint leftEye2 = [face2[@"leftEye"] CGPointValue];
        
        // 计算嘴巴到左眼的距离比例
        CGFloat distance1 = sqrt(pow(mouth1.x - leftEye1.x, 2) + pow(mouth1.y - leftEye1.y, 2));
        CGFloat distance2 = sqrt(pow(mouth2.x - leftEye2.x, 2) + pow(mouth2.y - leftEye2.y, 2));
        
        if (distance1 > 0 && distance2 > 0) {
            CGFloat distanceRatio = MIN(distance1/distance2, distance2/distance1);
            totalDistance += distanceRatio;
            featureCount++;
        }
    }
    
    // 比较面部宽高比
    if (face1[@"aspectRatio"] && face2[@"aspectRatio"]) {
        CGFloat aspectRatio1 = [face1[@"aspectRatio"] floatValue];
        CGFloat aspectRatio2 = [face2[@"aspectRatio"] floatValue];
        
        if (aspectRatio1 > 0 && aspectRatio2 > 0) {
            CGFloat aspectRatioRatio = MIN(aspectRatio1/aspectRatio2, aspectRatio2/aspectRatio1);
            totalDistance += aspectRatioRatio;
            featureCount++;
        }
    }
    
    if (featureCount > 0) {
        return totalDistance / featureCount;
    }
    
    return 0.0;
}

- (void)saveRegisteredFaces {
    // 保存已注册面部数据到文件
    NSString *path = [self facesDataPath];
    [self.registeredFaces writeToFile:path atomically:YES];
}

- (void)loadRegisteredFaces {
    // 从文件加载已注册面部数据
    NSString *path = [self facesDataPath];
    NSDictionary *savedFaces = [NSDictionary dictionaryWithContentsOfFile:path];
    if (savedFaces) {
        self.registeredFaces = [NSMutableDictionary dictionaryWithDictionary:savedFaces];
    }
}

- (NSString *)facesDataPath {
    // 获取存储路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    return [documentsDirectory stringByAppendingPathComponent:@"registeredFaces.plist"];
}

@end
