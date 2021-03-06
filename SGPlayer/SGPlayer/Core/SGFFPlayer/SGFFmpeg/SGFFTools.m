//
//  SGFFTools.m
//  SGMediaKit
//
//  Created by Single on 19/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFTools.h"
#import "SGFFDecoder.h"

#pragma mark - Util Function

void sg_ff_log(void * context, int level, const char * format, va_list args)
{
#if SGFFFFmpegLogEnable
        NSString * message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args];
        SGFFFFmpegLog(@"SGFFLog : %@", message);
#endif
}

NSError * sg_ff_check_error(int result)
{
    return sg_ff_check_error_code(result, -1);
}

NSError * sg_ff_check_error_code(int result, NSUInteger errorCode)
{
    if (result < 0) {
        char * error_string_buffer = malloc(256);
        av_strerror(result, error_string_buffer, 256);
        NSString * error_string = [NSString stringWithFormat:@"ffmpeg code : %d, ffmpeg msg : %s", result, error_string_buffer];
        NSError * error = [NSError errorWithDomain:error_string code:errorCode userInfo:nil];
        return error;
    }
    return nil;
}

void sg_ff_convert_AVFrame_to_YUV(UInt8 * src, int linesize, int width, int height, UInt8 ** dst, int * lenght)
{
    width = MIN(linesize, width);
    * dst = malloc(width * height);
    UInt8 * temp = * dst;
    memset(* dst, 0, width * height);
    * lenght = width * height;
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, width);
        temp += width;
        src += linesize;
    }
}

double sg_ff_get_fps(AVStream * stream, double timebase)
{
    double fps;
    if (stream->avg_frame_rate.den > 0 && stream->avg_frame_rate.num > 0) {
        fps = av_q2d(stream->avg_frame_rate);
    } else if (stream->r_frame_rate.den > 0 && stream->r_frame_rate.num > 0) {
        fps = av_q2d(stream->r_frame_rate);
    } else {
        fps = 1.0 / timebase;
    }
    return fps;
}

double sg_ff_get_timebase(AVStream * stream, double default_timebase)
{
    double timebase;
    if (stream->time_base.den > 0 && stream->time_base.num > 0) {
        timebase = av_q2d(stream->time_base);
    } else {
        timebase = default_timebase;
    }
    return timebase;
}

NSDictionary * sg_ff_dict_conver(AVDictionary * avDictionary)
{
    if (avDictionary == NULL) return nil;
    
    int count = av_dict_count(avDictionary);
    if (count <= 0) return nil;
    
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    AVDictionaryEntry * entry = NULL;
    while ((entry = av_dict_get(avDictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        @autoreleasepool {
            NSString * key = [NSString stringWithUTF8String:entry->key];
            NSString * value = [NSString stringWithUTF8String:entry->value];
            [dictionary setObject:value forKey:key];
        }
    }
    
    return dictionary;
}

