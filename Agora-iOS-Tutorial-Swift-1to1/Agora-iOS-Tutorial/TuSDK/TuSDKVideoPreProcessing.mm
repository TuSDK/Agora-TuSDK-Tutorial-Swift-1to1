

#import <Foundation/Foundation.h>
#import "TuSDKVideoPreProcessing.h"

#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import <AgoraRtcKit/IAgoraRtcEngine.h>
#import <AgoraRtcKit/IAgoraMediaEngine.h>
#import <string.h>
#import <CoreVideo/CVPixelBuffer.h>

// TuSDK mark
#import <libyuv/libyuv.h>
#import "TuSDKManager.h"

class TuSDKAudioFrameObserver : public agora::media::IAudioFrameObserver
{
public:
    virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
    {
        return true;
    }
    virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
    {
        return true;
    }
    virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
    {
        return true;
    }
};

NSTimeInterval _lastTime;
NSUInteger _count;

CFDictionaryRef empty; // empty value for attr value.
CFMutableDictionaryRef attrs;

class TuSDKVideoFrameObserver : public agora::media::IVideoFrameObserver
{
public:
    
    virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
    {
        @autoreleasepool
        {
            CVReturn err = 0;
            CVPixelBufferRef renderTarget;
            
            err = CVPixelBufferCreate(kCFAllocatorDefault,
                                      (int)videoFrame.width,
                                      (int)videoFrame.height,
                                      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                      attrs,
                                      &renderTarget);
            
            if (err)
            {
                NSLog(@"FBO size: %d, %d", videoFrame.width, videoFrame.height);
            }
            
            
            CVPixelBufferLockBaseAddress(renderTarget, 0);
            unsigned char *baseAddress = (unsigned char *)CVPixelBufferGetBaseAddress(renderTarget);
            
            Byte* srcYPtr = (Byte*)videoFrame.yBuffer;
            Byte* srcUPtr = (Byte*)videoFrame.uBuffer;
            Byte* srcVPtr = (Byte*)videoFrame.vBuffer;

            Byte* YPtr = (Byte*)CVPixelBufferGetBaseAddressOfPlane(renderTarget, 0);
            size_t YStride = CVPixelBufferGetBytesPerRowOfPlane(renderTarget, 0);
            size_t YStrideMin = MIN(videoFrame.yStride, YStride);
            Byte* UVPtr = (Byte*)CVPixelBufferGetBaseAddressOfPlane(renderTarget, 1);
            size_t UVStride = CVPixelBufferGetBytesPerRowOfPlane(renderTarget, 1);
            
            for (size_t h = 0; h < videoFrame.height; h++)
            {
                memcpy(YPtr + h * YStride, srcYPtr + h * videoFrame.yStride, YStrideMin);
            }
            
            for (size_t h = 0; h < videoFrame.height / 2; h++)
            {
                srcUPtr = (Byte*)videoFrame.uBuffer + h * videoFrame.uStride;
                srcVPtr = (Byte*)videoFrame.vBuffer + h * videoFrame.vStride;
                
                Byte *dstUVPtr = UVPtr + h * UVStride;
                
                for (size_t w = 0; w < videoFrame.width / 2; w++)
                {
                    dstUVPtr[w * 2] = srcUPtr[w];
                    dstUVPtr[w * 2 + 1] = srcVPtr[w];
                }
            }
            
            
            CVPixelBufferUnlockBaseAddress(renderTarget, 0);
                
            // TuSDK mark - 调用 syncProcessPixelBuffer 处理视频帧，后续根据得到的 newBuffer信息 写入videoFrame中，其余逻辑可保持不变
            CVPixelBufferRef newBuffer = [[TuSDKManager sharedManager] syncProcessPixelBuffer:renderTarget
                                                                                    timeStamp:videoFrame.renderTimeMs
                                                                                     rotation:videoFrame.rotation];
            
            CVPixelBufferLockBaseAddress(newBuffer, 0);
            baseAddress = (unsigned char *)CVPixelBufferGetBaseAddress(newBuffer);
            
            {
                VideoFrame vf;

                vf.width = videoFrame.height;
                vf.height = videoFrame.width;
                vf.yStride = vf.width;
                vf.uStride = vf.yStride / 2;
                vf.vStride = vf.yStride / 2;
                vf.yBuffer = malloc(vf.height * vf.yStride);
                vf.uBuffer = malloc(vf.height * vf.uStride);
                vf.vBuffer = malloc(vf.height * vf.vStride);

                libyuv::ARGBToI420(baseAddress,
                                   (int)CVPixelBufferGetBytesPerRow(newBuffer),
                                   (uint8 *)vf.yBuffer,
                                   vf.yStride,
                                   (uint8 *)vf.uBuffer,
                                   vf.uStride,
                                   (uint8 *)vf.vBuffer,
                                   vf.vStride,
                                   vf.width,
                                   vf.height);
                
                libyuv::I420Rotate((uint8 *)vf.yBuffer,
                                   vf.yStride,
                                   (uint8 *)vf.uBuffer,
                                   vf.uStride,
                                   (uint8 *)vf.vBuffer,
                                   vf.vStride,
                                   (uint8 *)videoFrame.yBuffer,
                                   videoFrame.yStride,
                                   (uint8 *)videoFrame.uBuffer,
                                   videoFrame.uStride,
                                   (uint8 *)videoFrame.vBuffer,
                                   videoFrame.vStride,
                                   vf.width,
                                   vf.height,
                                   libyuv::RotationMode::kRotate270);

                free(vf.yBuffer);
                free(vf.uBuffer);
                free(vf.vBuffer);

            }
            
            CVPixelBufferUnlockBaseAddress(newBuffer, 0);
            CFRelease(renderTarget);
        
            return true;
        }
    }
        
    
    virtual bool onRenderVideoFrame(unsigned int uid, VideoFrame& videoFrame) override
    {
        return true;
    }
};

@interface TuSDKVideoPreProcessing()

@end

static TuSDKVideoFrameObserver s_videoFrameObserver;

@implementation TuSDKVideoPreProcessing

+ (int)registerVideoPreprocessing:(AgoraRtcEngineKit*) kit
{
    if (!kit) {
        return -1;
    }
    
    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
    if (mediaEngine)
    {
        mediaEngine->registerVideoFrameObserver(&s_videoFrameObserver);
        
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
    }
    return 0;
}


+ (int)deregisterVideoPreprocessing:(AgoraRtcEngineKit*) kit
{
    if (!kit) {
        return -1;
    }

    //    NSLog(@"（CF）attrs:%ld,empty:%ld",count1);
    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
    if (mediaEngine)
    {
        //mediaEngine->registerAudioFrameObserver(NULL);
        mediaEngine->registerVideoFrameObserver(NULL);
    }
    
    CFRelease(empty);
    
    NSInteger count1 = CFGetRetainCount(attrs);
    for (NSInteger i = 0; i < count1; i++) {
        CFRelease(attrs);
    }
    
    return 0;
}

@end
