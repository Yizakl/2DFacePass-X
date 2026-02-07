// 注意：此文件仅用于VSCode语法检查
// 实际构建时，Theos会提供完整的头文件和框架支持

// 添加必要的导入以避免VSCode错误
#ifdef __cplusplus
extern "C" {
#endif

#ifdef __OBJC__
@class NSObject;
#endif

#ifdef __cplusplus
}
#endif

// 简化的PrefsController定义
@interface PrefsController
@end

@implementation PrefsController
@end

// 注册控制器
__attribute__((constructor)) static void InitializePreferenceLoader(void) {
    // 实际实现会在构建时由Theos处理
}
