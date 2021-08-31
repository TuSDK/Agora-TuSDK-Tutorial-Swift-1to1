/********************************************************
 * @file    : TuSDKManager.m
 * @author  : Copyright © http://tutucloud.com/
 * @date    : 2020-08-01
 * @brief   :
*********************************************************/

#import <Foundation/Foundation.h>
#import "TuSDKFramework.h"

NS_ASSUME_NONNULL_BEGIN

@interface TuSDKManager : NSObject

@property (nonatomic, assign, readonly) BOOL isInitedTuSDK; // 是否初始化SDK
@property (nonatomic, assign, readonly) BOOL isInitFilterPipeline; // 是否初始化滤镜处理器

@property (nonatomic, assign) BOOL enableLiveSticker; // 是否开启动态贴纸 (默认: YES)
@property (nonatomic, assign) BOOL enableLiveBeauty;  // 是否开启美肤功能 (默认: YES)

#pragma mark - 初始化
+ (instancetype)sharedManager;

/**
 *  初始化SDK
 *
 *  @param appKey 应用秘钥
 */
- (void)initSdkWithAppKey:(NSString *)appKey;

/**
 *  布局TuSDK功能的相关视图，统一配置：滤镜+贴纸+美颜
 *  @param superView 滤镜视图需要展示的父视图，如果穿nil即不会默认添加上去，需要各自面板再添加到想要的view上
 */
- (void)configTuSDKViewWithSuperView:(UIView*)superView;


/**
 Process a video sample and return result soon

 @param sampleBuffer SampleBuffer Buffer to process
 @return Video PixelBuffer
 */
- (CVPixelBufferRef)syncProcessSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer timeStamp:(int64_t)timeStamp;
- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer timeStamp:(int64_t)timeStamp rotation:(int)rotation;

@end

NS_ASSUME_NONNULL_END
