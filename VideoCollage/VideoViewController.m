//
//  ViewController.m
//  VideoCollage
//
//  Created by Dmitry Utenkov on 12.06.13.
//  Copyright (c) 2013 Video Collage company. All rights reserved.
//

#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"

@interface VideoViewController ()

@property (nonatomic, retain) NSMutableArray *assetReaders;

@property (nonatomic, assign) CMTime frameTime;

@property (nonatomic, retain) NSURL *outputVideoFileURL;

@property (nonatomic, retain) AVAssetWriter *writer;
@property (nonatomic, retain) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferAdaptor;

@property (nonatomic, retain) NSMutableArray *videoFrames;
@property (nonatomic, retain) NSMutableArray *videoRects;

@end

@implementation VideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

        _assetReaders = [[NSMutableArray alloc] init];
        for (int i = 1; i <= 4; i++) {
            NSString *videoName = [NSString stringWithFormat:@"Video%d", i];
            NSString *videoSamplePath = [[NSBundle mainBundle] pathForResource:videoName ofType:@"mp4"];
            NSURL *url = [NSURL fileURLWithPath:videoSamplePath];
            AVAsset *asset = [AVAsset assetWithURL:url];
            [_assetReaders addObject:[self setupReader:asset]];
        }
        
        NSString *videoFilePath = [NSString stringWithFormat:@"%@/Documents/movie.m4v", NSHomeDirectory()];
        _outputVideoFileURL = [[NSURL fileURLWithPath:videoFilePath] retain];
        
        _frameTime = CMTimeMake(0, 30);
        
        
        _videoFrames = [[NSMutableArray arrayWithCapacity:_assetReaders.count] retain];
        
        // Stubs for future frames
        for (id stub in _assetReaders) {
            [_videoFrames addObject:[NSNull null]];
        }
        
        _videoRects = [[NSMutableArray alloc] init];
        [_videoRects addObject:[NSValue valueWithCGRect:CGRectMake(60,20, 0, 0)]];
        [_videoRects addObject:[NSValue valueWithCGRect:CGRectMake(380,20, 0, 0)]];
        [_videoRects addObject:[NSValue valueWithCGRect:CGRectMake(60,260, 0, 0)]];
        [_videoRects addObject:[NSValue valueWithCGRect:CGRectMake(380,260, 0, 0)]];
    }
    return self;
}


- (IBAction)collageButtonPressed:(id)sender {
    [self.collageButton setEnabled:NO];
    
    [[MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES] setLabelText:@"Making collage..."];
    
    [self performSelector:@selector(makeCollage) withObject:nil afterDelay:0.1];
}

- (void)makeCollage {
    self.writer = [self setupAssetWriter];
    [self.writer startWriting];
    [self.writer startSessionAtSourceTime:kCMTimeZero];
    
    for (AVAssetReader *reader in self.assetReaders) {
        [reader startReading];
    }
    
    @autoreleasepool {
        [self drawVideoFrame:self.assetReaders.count-1];
    }
    
    [[[[self writer] inputs] objectAtIndex:0] markAsFinished];
    [[self writer] performSelectorInBackground:@selector(finishWritingWithCompletionHandler:)
                                    withObject:^{}];
    
    NSLog(@"Video saved");
    [self.collageButton setEnabled:YES];
    [MBProgressHUD hideAllHUDsForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
}

- (void)drawVideoFrame:(NSInteger)videoIndex {
    
    if (videoIndex < 0) {
        return;
    }
    
    while ([[self.assetReaders objectAtIndex:videoIndex] status] == AVAssetReaderStatusReading) {
        AVAssetReaderOutput* output = [[[self.assetReaders objectAtIndex:videoIndex] outputs] objectAtIndex:0];
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if (sampleBuffer != NULL) {
            UIImage *frame = [self imageFromCMSampleBuffer:sampleBuffer];
            [self.videoFrames replaceObjectAtIndex:videoIndex withObject:frame];
            
            // Recursion
            [self drawVideoFrame:videoIndex-1];
        } else {
            break;
        }
        [self drawFrame:self.videoFrames];
    }
}

- (void)drawFrame:(NSArray *)videoFrames {

    CGRect videoRect = [self finalVideoRect];
    
    UIImage *background = [UIImage imageNamed:@"TemplateMask.png"];
    
    UIGraphicsBeginImageContext(videoRect.size);
    
    [background drawInRect:CGRectMake(0, 0, videoRect.size.width, videoRect.size.height)];
    
    NSUInteger index = 0;
    
    for (UIImage *videoFrame in videoFrames) {
        CGRect frameRect = [[self.videoRects objectAtIndex:index] CGRectValue];
        frameRect.size = [self adjustSizeToFrameRect:videoFrame.size];
        [videoFrame drawInRect:frameRect
                blendMode:kCGBlendModeNormal
                    alpha:1];
        index++;
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();

    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:[newImage CGImage]];
    [self newFrameReady:buffer];
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    CVPixelBufferRef pxbuffer = NULL;
    
    CVPixelBufferPoolCreatePixelBuffer (NULL, self.assetWriterPixelBufferAdaptor.pixelBufferPool, &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0)); 
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (CGSize)adjustSizeToFrameRect:(CGSize)size {
    float adjustedWidth = 0;
    float adjustedHeight = 0;
    if (size.width > size.height) {
        // Landscape oriented video (adjust to width)
        adjustedWidth = 200;
        adjustedHeight = size.height / size.width * 200;
        
    } else {
        // Portrait oriented video (adjust to height)
        adjustedHeight = 200;
        adjustedWidth = size.width / size.height * 200;
    }
    return CGSizeMake(adjustedWidth, adjustedHeight);
}

- (UIImage *)imageFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
        
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
    UIImage *image = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationUp];
        
    /*We relase the CGImageRef*/
    CGImageRelease(newImage);
    
    return image;
}

#pragma mark - Service methods

- (AVAssetReader *)setupReader:(AVAsset * )asset {
    NSError *error = nil;
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] , kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                        outputSettings:videoSettings];
    if ([assetReader canAddOutput:assetReaderOutput]) {
        [assetReader addOutput:assetReaderOutput];
    }
    return [assetReader autorelease];
}

- (AVAssetWriter *)setupAssetWriter {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[self outputVideoFileURL] path]]) {
        [[NSFileManager defaultManager] removeItemAtURL:[self outputVideoFileURL] error:nil];
    }
    
    CGSize frameSize = [self finalVideoRect].size;
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:self.outputVideoFileURL
                                                           fileType:AVFileTypeAppleM4V
                                                              error:&error];
    if(error) {
        NSLog(@"error creating AssetWriter: %@",[error description]);
    }
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                    AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey,
                                   nil];
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                          outputSettings:videoSettings];
    writerInput.expectsMediaDataInRealTime = YES;
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    [attributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGImageCompatibilityKey];
    [attributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey];
    
    self.assetWriterPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                                          assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                          sourcePixelBufferAttributes:attributes];
    [videoWriter addInput:writerInput];
    
    return [videoWriter autorelease];
}

- (void)newFrameReady:(CVPixelBufferRef)pixelBuffer {
    CMTime frameTime = self.frameTime;
    
    if (![[[[self writer] inputs] objectAtIndex:0] isReadyForMoreMediaData]) {
        return;
    }
    
    
    BOOL result = [self.assetWriterPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:frameTime];
    
    if (result == NO)
    {
        NSLog(@"failed to append buffer");
        NSLog(@"The error is %@", [self.writer error]);
    }
    else
    {
        frameTime.value += 1;
        self.frameTime = frameTime;
    }
}

- (CGRect)finalVideoRect {
    return CGRectMake(0, 0, 640, 480);
}

@end