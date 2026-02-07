#import "CameraManager.h"

@interface CameraManager ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, assign) BOOL isRunning;

@end

@implementation CameraManager

- (instancetype)init {
    if (self = [super init]) {
        _captureSession = [[AVCaptureSession alloc] init];
        _isRunning = NO;
    }
    return self;
}

- (void)startCamera {
    if (_isRunning) return;
    
    NSError *error = nil;
    
    // 获取前置摄像头
    self.frontCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!self.frontCamera) {
        NSLog(@"Error: No front camera found");
        return;
    }
    
    // 设置相机参数，提高启动速度
    if ([self.frontCamera lockForConfiguration:&error]) {
        // 设置较低的视频分辨率以提高性能
        [self.frontCamera setActiveFormat:[self bestFormatForDevice:self.frontCamera]];
        [self.frontCamera unlockForConfiguration];
    }
    
    // 创建视频输入
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontCamera error:&error];
    if (error) {
        NSLog(@"Error creating video input: %@", error);
        return;
    }
    
    // 创建视频输出
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // 配置视频输出
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:YES]; // 丢弃迟到的帧，提高实时性
    [self.videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    
    // 创建专用队列，提高处理效率
    dispatch_queue_t videoQueue = dispatch_queue_create("com.example.camera.processing", DISPATCH_QUEUE_SERIAL);
    [self.videoOutput setSampleBufferDelegate:self queue:videoQueue];
    
    // 配置捕获会话
    [self.captureSession beginConfiguration];
    
    // 设置会话预设，平衡质量和速度
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
    
    if ([self.captureSession canAddOutput:self.videoOutput]) {
        [self.captureSession addOutput:self.videoOutput];
    }
    
    // 设置视频输出格式
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isVideoOrientationSupported]) {
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    [self.captureSession commitConfiguration];
    
    // 启动捕获会话
    [self.captureSession startRunning];
    _isRunning = YES;
    NSLog(@"Camera started successfully");
}

- (void)stopCamera {
    if (!_isRunning) return;
    
    [self.captureSession stopRunning];
    _isRunning = NO;
    NSLog(@"Camera stopped");
}

- (BOOL)isCameraRunning {
    return _isRunning;
}

- (AVCaptureDeviceFormat *)bestFormatForDevice:(AVCaptureDevice *)device {
    // 选择最佳的相机格式，平衡性能和质量
    AVCaptureDeviceFormat *bestFormat = nil;
    CGFloat bestScore = 0.0;
    
    for (AVCaptureDeviceFormat *format in device.formats) {
        CMFormatDescriptionRef formatDescription = format.formatDescription;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
        
        // 计算评分：优先选择中等分辨率，平衡性能和质量
        CGFloat resolutionScore = 1.0 / (1.0 + abs((int)(dimensions.width * dimensions.height - 640 * 480)) / (640.0 * 480.0));
            
            // 检查是否支持该格式的帧率
            NSArray *frameRates = format.videoSupportedFrameRateRanges;
            if (frameRates.count > 0) {
                AVCaptureDeviceFormat *currentFormat = format;
                CGFloat frameRateScore = 0.0;
                
                for (AVFrameRateRange *range in frameRates) {
                    if (range.maxFrameRate >= 15.0) {
                        frameRateScore = 1.0;
                        break;
                    }
                }
                
                CGFloat totalScore = resolutionScore * 0.7 + frameRateScore * 0.3;
                
                if (totalScore > bestScore) {
                    bestScore = totalScore;
                    bestFormat = currentFormat;
                }
            }
        }
    }
    
    return bestFormat ?: device.activeFormat;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraDidCaptureFrame:)]) {
        [self.delegate cameraDidCaptureFrame:sampleBuffer];
    }
}

@end
