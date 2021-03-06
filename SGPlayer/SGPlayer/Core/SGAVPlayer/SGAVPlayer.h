//
//  SGAVPlayer.h
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SGPlayer.h"

@interface SGAVPlayer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;

+ (instancetype)playerWithAbstractPlayer:(SGPlayer *)abstractPlayer;

@property (nonatomic, weak, readonly) SGPlayer * abstractPlayer;
@property (nonatomic, strong, readonly) AVPlayer * avPlayer;

@property (nonatomic, assign, readonly) SGPlayerState state;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval bitrate;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;
@property (nonatomic, assign, readonly) BOOL seeking;

- (void)replaceVideo;
- (void)reloadVolume;

- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler;

- (UIImage *)snapshotAtCurrentTime;
- (CVPixelBufferRef)pixelBufferAtCurrentTime;

@end
