//
//  SGFFPlayer.h
//  SGMediaKit
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayer.h"
#import "SGAVView.h"

@interface SGFFPlayer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)player;

@property (nonatomic, weak) SGPlayer * abstractPlayer;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, assign, readonly) SGVideoType videoType;
- (void)replaceVideoWithURL:(NSURL *)contentURL;
- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType;

// preview
@property (nonatomic, assign) SGDisplayMode displayMode;
@property (nonatomic, strong, readonly) SGAVView * view;      // graphics view
@property (nonatomic, assign) BOOL viewAnimationHidden;     // default is NO;
- (UIImage *)snapshot;
- (void)setViewTapBlock:(void(^)())block;   // view tap action

// control
@property (nonatomic, assign) SGPlayerBackgroundMode backgroundMode;    // background mode
@property (nonatomic, assign, readonly) SGPlayerState state;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval progress;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval playableTime;
@property (nonatomic, assign) NSTimeInterval playableBufferInterval;    // default is 2s
@property (nonatomic, assign, readonly) BOOL seeking;
@property (nonatomic, assign) CGFloat volume;

- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void(^)(BOOL finished))completeHandler;

@end