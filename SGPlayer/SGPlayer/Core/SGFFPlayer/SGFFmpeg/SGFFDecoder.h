//
//  SGFFDecoder.h
//  SGMediaKit
//
//  Created by Single on 05/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SGFFFrame.h"

typedef NS_ENUM(NSUInteger, SGFFDecoderErrorCode) {
    SGFFDecoderErrorCodeFormatOpenInput,
    SGFFDecoderErrorCodeFormatFindStreamInfo,
    SGFFDecoderErrorCodeStreamNotFound,
    SGFFDecoderErrorCodeCodecFindDecoder,
    SGFFDecoderErrorCodeCodecOpen2,
    SGFFDecoderErrorCodeAuidoSwrInit,
};

@class SGFFDecoder;

@protocol SGFFDecoderDelegate <NSObject>

@optional

// open input stream
- (void)decoderWillOpenInputStream:(SGFFDecoder *)decoder;
- (void)decoderDidOpenInputStream:(SGFFDecoder *)decoder;

// open video/audio stream
- (void)decoderDidOpenVideoStream:(SGFFDecoder *)decoder;
- (void)decoderDidOpenAudioStream:(SGFFDecoder *)decoder;

// decode frames
- (void)decoderDidPrepareToDecodeFrames:(SGFFDecoder *)decoder;

// end of file
- (void)decoderDidEndOfFile:(SGFFDecoder *)decoder;

// error callback
- (void)decoder:(SGFFDecoder *)decoder didError:(NSError *)error;

@end

@protocol SGFFDecoderOutput <NSObject>

- (void)decoder:(SGFFDecoder *)decoder renderVideoFrame:(SGFFVideoFrame *)videoFrame;

@end

@interface SGFFDecoder : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)decoderWithContentURL:(NSURL *)contentURL delegate:(id <SGFFDecoderDelegate>)delegate output:(id <SGFFDecoderOutput>)output;

@property (nonatomic, copy, readonly) NSURL * contentURL;
@property (nonatomic, copy, readonly) NSDictionary * metadata;
@property (nonatomic, assign, readonly) CGSize presentationSize;
@property (nonatomic, assign, readonly) NSTimeInterval fps;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (atomic, assign, readonly) BOOL closed;
@property (atomic, assign, readonly) BOOL endOfFile;
@property (atomic, assign, readonly) BOOL seeking;
@property (atomic, assign, readonly) BOOL reading;
@property (atomic, assign, readonly) BOOL decoding;
@property (atomic, assign, readonly) BOOL prepareToDecode;

@property (atomic, assign, readonly) BOOL videoEnable;
@property (atomic, assign, readonly) BOOL audioEnable;

@property (atomic, assign, readonly) NSInteger videoStreamIndex;
@property (atomic, assign, readonly) NSInteger audioStreamIndex;

@property (nonatomic, copy, readonly) NSArray <NSNumber *> * videoStreamIndexs;
@property (nonatomic, copy, readonly) NSArray <NSNumber *> * audioStreamIndexs;

- (SGFFAudioFrame *)fetchAudioFrame;

@property (nonatomic, assign) CGFloat volume;

@property (nonatomic, assign, readonly) BOOL seekEnable;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL finished))completeHandler;

- (void)closeFile;      // when release of active calls, or when called in dealloc might block the thread

@end
