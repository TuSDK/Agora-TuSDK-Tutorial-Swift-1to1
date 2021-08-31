//
//  TuSDKVideoPreProcessing.h
//  OpenVideoCall
//
//  Created by Alex Zheng on 7/28/16.
//  Copyright © 2016 Agora.io All rights reserved.
//

#import <UIKit/UIKit.h>

@class AgoraRtcEngineKit;

@interface TuSDKVideoPreProcessing : NSObject

+ (int)registerVideoPreprocessing:(AgoraRtcEngineKit*)kit;

+ (int)deregisterVideoPreprocessing:(AgoraRtcEngineKit*)kit;

@end
		
