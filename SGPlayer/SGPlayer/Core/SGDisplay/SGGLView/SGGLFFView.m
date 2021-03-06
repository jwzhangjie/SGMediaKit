//
//  SGGLFFView.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLFFView.h"
#import "SGGLFFProgram.h"
#import "SGGLAVProgram.h"
#import "SGGLAVTexture.h"

@interface SGGLFFView ()

{
    GLuint _avTexture[3];
}

@property (nonatomic, strong) SGGLAVTexture * cvTexture;

@property (nonatomic, assign) BOOL avSetupToken;
@property (nonatomic, assign) BOOL cvSetupToken;

@property (nonatomic, strong) SGGLProgram * program;
@property (nonatomic, strong) SGGLFFProgram * avProgram;
@property (nonatomic, strong) SGGLAVProgram * cvProgram;

@property (atomic, strong) SGFFVideoFrame * videoFrame;

@end

@implementation SGGLFFView

- (void)renderFrame:(__kindof SGFFVideoFrame *)frame
{
    self.videoFrame = frame;
    [self displayAsyncOnMainThread];
}

- (BOOL)updateTextureAspect:(CGFloat *)aspect
{
    if (!self.videoFrame) return NO;

    /*
    assert(self.videoFrame.luma.length == self.videoFrame.width * self.videoFrame.height);
    assert(self.videoFrame.chromaB.length == (self.videoFrame.width * self.videoFrame.height) / 4);
    assert(self.videoFrame.chromaR.length == (self.videoFrame.width * self.videoFrame.height) / 4);
     */
    
    if ([self.videoFrame isKindOfClass:[SGFFAVYUVVideoFrame class]])
    {
        [self setupAVFrame];
        self.program = self.avProgram;
        
        SGFFAVYUVVideoFrame * frame = (SGFFAVYUVVideoFrame *)self.videoFrame;
        
        const int frameWidth = frame.width;
        const int frameHeight = frame.height;
        * aspect = (frameWidth * 1.0) / (frameHeight * 1.0);
        
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        
        const int widths[3]  = {
            frameWidth,
            frameWidth / 2,
            frameWidth / 2
        };
        const int heights[3] = {
            frameHeight,
            frameHeight / 2,
            frameHeight / 2
        };
        
        for (SGYUVChannel channel = SGYUVChannelLuma; channel < SGYUVChannelCount; channel++)
        {
            glActiveTexture(GL_TEXTURE0 + channel);
            glBindTexture(GL_TEXTURE_2D, self->_avTexture[channel]);
            glTexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_LUMINANCE,
                         widths[channel],
                         heights[channel],
                         0,
                         GL_LUMINANCE,
                         GL_UNSIGNED_BYTE,
                         frame->channel_pixels[channel]);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
    }
    else if ([self.videoFrame isKindOfClass:[SGFFCVYUVVideoFrame class]])
    {
        [self setupCVPixelBuffer];
        self.program = self.cvProgram;
        
        SGFFCVYUVVideoFrame * frame = (SGFFCVYUVVideoFrame *)self.videoFrame;
        
        if (!frame.pixelBuffer && !self.cvTexture.hasTexture) return NO;
        [self.cvTexture updateTextureWithPixelBuffer:frame.pixelBuffer aspect:aspect needRelease:NO];
    }
    
    return YES;
}

- (void)setupAVFrame
{
    if (!self.avSetupToken) {
        glGenTextures(3, self->_avTexture);
        self.avProgram = [SGGLFFProgram program];
        self.avSetupToken = YES;
    }
}

- (void)setupCVPixelBuffer
{
    if (!self.cvSetupToken) {
        self.cvTexture = [[SGGLAVTexture alloc] initWithContext:self.context];
        self.cvProgram = [SGGLAVProgram program];
        self.cvSetupToken = YES;
    }
}

- (void)setupSubClass
{
    [self setupAVFrame];
    [self setupCVPixelBuffer];
}

- (void)cleanTexture
{
    self.videoFrame = nil;
}

- (void)willDealloc
{
    if (self.avSetupToken) {
        glDeleteTextures(3, self->_avTexture);
        self.avSetupToken = NO;
    }
}

@end
