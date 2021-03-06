//
//  SGGLView.m
//  SGMediaKit
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGGLView.h"
#import "SGPlayerMacro.h"
#import "SGPlayer.h"
#import "SGGLNormalModel.h"
#import "SGGLVRModel.h"
#import "SGMatrix.h"
#import "SGDistortionRenderer.h"

@interface SGGLView () <GLKViewDelegate>

@property (nonatomic, assign) BOOL setupToken;
@property (nonatomic, weak) SGDisplayView * displayView;

@property (nonatomic, strong) SGGLNormalModel * normalModel;
@property (nonatomic, strong) SGGLVRModel * vrModel;
@property (nonatomic, strong) SGMatrix * matrix;
@property (nonatomic, strong) SGDistortionRenderer * distorionRenderer;

@end

@implementation SGGLView

+ (instancetype)viewWithDisplayView:(SGDisplayView *)displayView
{
    return [[self alloc] initWithDisplayView:displayView];
}

- (instancetype)initWithDisplayView:(SGDisplayView *)displayView
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.displayView = displayView;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!self.setupToken) {
        [self setup];
        self.setupToken = YES;
    }
    self.distorionRenderer.viewportSize = [self pixelSize];
}

- (CGSize)pixelSize
{
    NSInteger scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(CGRectGetWidth(self.bounds) * scale, CGRectGetHeight(self.bounds) * scale);
    return size;
}

#pragma mark - setup

- (void)setup
{
    self.backgroundColor = [UIColor blackColor];
    [self setupGLKView];
    [self setupProgram];
    [self setupModel];
    [self setupSubClass];
}

- (void)setupGLKView
{
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    self.delegate = self;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
}

- (void)setupModel
{
    self.normalModel = [SGGLNormalModel model];
    self.vrModel = [SGGLVRModel model];
}

- (void)displayAsyncOnMainThread
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayIfApplicationActive];
    });
}

- (void)displayIfApplicationActive
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) return;
    [self display];
}

- (void)cleanEmptyBuffer
{
    [self cleanTexture];
    [self displayAsyncOnMainThread];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self render];
}

- (void)render
{
    [EAGLContext setCurrentContext:self.context];
    
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    SGVideoType videoType = self.displayView.abstractPlayer.videoType;
    SGDisplayMode displayMode = self.displayView.abstractPlayer.displayMode;
    SGGravityMode gravityMode = self.displayView.abstractPlayer.viewGravityMode;
    
    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
        [self.distorionRenderer beforDrawFrame];
    }

    CGFloat aspect = 16.0/9.0;
    BOOL success = [self updateTextureAspect:&aspect];
    if (!success) return;
    
    [self.program use];
    [self.program bindVariable];
    
    NSInteger scale = [UIScreen mainScreen].scale;
    CGRect rect = self.bounds;
    CGFloat rectAspect = rect.size.width / rect.size.height;
    if (videoType == SGVideoTypeVR) aspect = 16.0/9.0;
    switch (gravityMode) {
        case SGGravityModeResize:
            break;
        case SGGravityModeResizeAspect:
            if (rectAspect < aspect) {
                CGFloat height = rect.size.width / aspect;
                rect = CGRectMake(0, (rect.size.height - height) / 2, rect.size.width, height);
            } else if (rectAspect > aspect) {
                CGFloat width = rect.size.height * aspect;
                rect = CGRectMake((rect.size.width - width) / 2, 0, width, rect.size.height);
            }
            break;
        case SGGravityModeResizeAspectFill:
            if (rectAspect < aspect) {
                CGFloat width = rect.size.height * aspect;
                rect = CGRectMake(-(width - rect.size.width) / 2, 0, width, rect.size.height);
            } else if (rectAspect > aspect) {
                CGFloat height = rect.size.width / aspect;
                rect = CGRectMake(0, -(height - rect.size.height) / 2, rect.size.width, height);
            }
            break;
    }
    rect = CGRectMake(CGRectGetMinX(rect) * scale, CGRectGetMinY(rect) * scale, CGRectGetWidth(rect) * scale, CGRectGetHeight(rect) * scale);
    
    switch (videoType) {
        case SGVideoTypeNormal:
        {
            [self.normalModel bindPositionLocation:self.program.position_location textureCoordLocation:self.program.texture_coord_location];
            glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
            [self.program updateMatrix:GLKMatrix4Identity];
            glDrawElements(GL_TRIANGLES, self.normalModel.index_count, GL_UNSIGNED_SHORT, 0);
        }
            break;
        case SGVideoTypeVR:
        {
            [self.vrModel bindPositionLocation:self.program.position_location textureCoordLocation:self.program.texture_coord_location];
            switch (displayMode) {
                case SGDisplayModeNormal:
                {
                    GLKMatrix4 matrix;
                    BOOL success = [self.matrix singleMatrixWithSize:rect.size matrix:&matrix fingerRotation:self.displayView.fingerRotation];
                    if (success) {
                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
                        [self.program updateMatrix:matrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
                case SGDisplayModeBox:
                {
                    GLKMatrix4 leftMatrix;
                    GLKMatrix4 rightMatrix;
                    BOOL success = [self.matrix doubleMatrixWithSize:rect.size leftMatrix:&leftMatrix rightMatrix:&rightMatrix];
                    if (success) {
                        glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
                        [self.program updateMatrix:leftMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                        
                        glViewport(CGRectGetWidth(rect)/2 + rect.origin.x, rect.origin.y, CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
                        [self.program updateMatrix:rightMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
            }
        }
            break;
    }
    
    if (videoType == SGVideoTypeVR && displayMode == SGDisplayModeBox) {
        [self bindDrawable];
        [self.distorionRenderer afterDrawFrame];
    }
}

- (SGMatrix *)matrix
{
    if (!_matrix) {
        _matrix = [[SGMatrix alloc] init];
    }
    return _matrix;
}

- (SGDistortionRenderer *)distorionRenderer
{
    if (!_distorionRenderer) {
        _distorionRenderer = [SGDistortionRenderer distortionRenderer];
    }
    return _distorionRenderer;
}

- (void)dealloc
{
    [self willDealloc];
    [EAGLContext setCurrentContext:nil];
    SGPlayerLog(@"%@ release", self.class);
}

- (void)setupProgram {}
- (void)setupSubClass {}
- (BOOL)updateTextureAspect:(CGFloat *)aspect {return NO;}
- (void)cleanTexture {}
- (SGGLProgram *)program {return nil;}
- (void)willDealloc {}

@end
