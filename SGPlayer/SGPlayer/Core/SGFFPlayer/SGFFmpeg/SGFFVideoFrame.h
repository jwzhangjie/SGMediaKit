//
//  SGFFVideoFrame.h
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFFrame.h"
#import <AVFoundation/AVFoundation.h>
#import "avformat.h"

typedef NS_ENUM(int, SGYUVChannel) {
    SGYUVChannelLuma = 0,
    SGYUVChannelChromaB = 1,
    SGYUVChannelChromaR = 2,
    SGYUVChannelCount = 3,
};

@interface SGFFVideoFrame : SGFFFrame

@end


// FFmpeg AVFrame YUV frame
@interface SGFFAVYUVVideoFrame : SGFFVideoFrame

{
@public
    UInt8 * channel_pixels[SGYUVChannelCount];
    int channel_lenghts[SGYUVChannelCount];
}

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

- (instancetype)initWithAVFrame:(AVFrame *)frame width:(int)width height:(int)height;

@end


// CoreVideo YUV frame
@interface SGFFCVYUVVideoFrame : SGFFVideoFrame

@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
