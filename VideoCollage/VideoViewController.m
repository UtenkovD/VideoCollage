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
#import "CROpenGLESVideoCapture.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

static NSInteger counter = 0;

@interface VideoViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) NSMutableArray *assetReaders;

@property (nonatomic, retain) NSMutableData *audioData;

@property (nonatomic, retain) AVAssetReader *reader;
@property (nonatomic, retain) AVAssetReaderOutput *readerOutput;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) AVAssetTrack *videoTrack;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) CMTime frameTime;

@property (nonatomic, retain)   NSURL                                   *outputVideoFileURL;

@property (nonatomic, retain) AVAssetWriter *writer;
@property (nonatomic, retain) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferAdaptor;


@end

@implementation VideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        NSString *videoSamplePath = [[NSBundle mainBundle] pathForResource:@"videoSample" ofType:@"mp4"];
        NSURL *url = [NSURL fileURLWithPath:videoSamplePath];
        AVAsset *asset = [AVAsset assetWithURL:url];
        
        _assetReaders = [[NSMutableArray alloc] init];
        
        [_assetReaders addObject:[self setupReader:asset]];
        [_assetReaders addObject:[self setupReader:asset]];
        
        NSString *videoFilePath = [NSString stringWithFormat:@"%@/Documents/movie.m4v", NSHomeDirectory()];
        _outputVideoFileURL = [[NSURL fileURLWithPath:videoFilePath] retain];
        
        _frameTime = CMTimeMake(0, 30);
        
        
    }
    return self;
}

- (void) resizeVideo:(NSURL *)videoPath outputPath:(NSURL *)outputPath
{
    
    NSURL *fullPath = outputPath;
    
    NSURL *path = videoPath;
    
    
    NSLog(@"Write Started");
    
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:fullPath fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:600], AVVideoWidthKey,
                                   [NSNumber numberWithInt:600], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [[AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings] retain];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    
    videoWriterInput.expectsMediaDataInRealTime = NO;
    
    [videoWriter addInput:videoWriterInput];
    
    
    
    
    AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:path options:nil];
    NSError *aerror = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:avAsset error:&aerror];
    
    
    AVAssetTrack *videoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    
    NSDictionary *videoOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    AVAssetReaderTrackOutput *asset_reader_output = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoOptions];
    
    [reader addOutput:asset_reader_output];
    
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    [reader startReading];
    
    CMSampleBufferRef buffer;
    
    
    while ( [reader status]==AVAssetReaderStatusReading )
    {
        if(![videoWriterInput isReadyForMoreMediaData])
            continue;
        
        buffer = [asset_reader_output copyNextSampleBuffer];
        
        
        NSLog(@"READING");
        
        if(buffer)
            [videoWriterInput appendSampleBuffer:buffer];
        
        NSLog(@"WRITTING...");
        
        
    }
    
    
    //Finish the session:
    [videoWriterInput markAsFinished];  
    [videoWriter finishWriting];
    NSLog(@"Write Ended");
    
}



- (AVAssetWriter *)setupAssetWriter {
    // Create a shallow queue for buffers going to the display for preview.
//    if (!previewBufferQueue) {
//        CMBufferCallbacks *callbacks;
//        callbacks = malloc(sizeof(CMBufferCallbacks));
//        callbacks->version = 0;
//        callbacks->getDuration = timeCallback;
//        callbacks->refcon = NULL;
//        callbacks->getDecodeTimeStamp = NULL;
//        callbacks->getPresentationTimeStamp = NULL;
//        callbacks->isDataReady = NULL;
//        callbacks->compare = NULL;
//        callbacks->dataBecameReadyNotification = NULL;
//        
//        CMBufferQueueCreate(kCFAllocatorDefault, 0, callbacks, &previewBufferQueue);
//    }

    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[self outputVideoFileURL] path]]) {
        [[NSFileManager defaultManager] removeItemAtURL:[self outputVideoFileURL] error:nil];
    }
    
//    NSError *error = nil;
//    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:[self outputVideoFileURL]
//                                                      fileType:AVFileTypeAppleM4V
//                                                         error:&error];
//    NSParameterAssert(writer);
//    
//    CGRect videoRect = CGRectMake(0, 0, 500, 500);
//    
//    NSNumber *videoWidth;
//    NSNumber *videoHeight;
//    
//    videoWidth = [NSNumber numberWithInt:500];
//    videoHeight = [NSNumber numberWithInt:500];
//    
//    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                   AVVideoCodecH264,    AVVideoCodecKey,
//                                   videoWidth,          AVVideoWidthKey,
//                                   videoHeight,         AVVideoHeightKey,
//                                   nil];
//    
//    
//    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
//                                                                         outputSettings:videoSettings];
//    
//    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
//                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
//                                                           [NSNumber numberWithInt:videoRect.size.width],      kCVPixelBufferWidthKey,
//                                                           [NSNumber numberWithInt:videoRect.size.height],     kCVPixelBufferHeightKey,
//                                                           [NSDictionary dictionary],                          kCVPixelBufferIOSurfacePropertiesKey,
//                                                           nil];
//    
//    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferAdaptor =
//    [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
//                                                                     sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
//    self.assetWriterPixelBufferAdaptor = assetWriterPixelBufferAdaptor;
//    
//    NSParameterAssert(writerInput);
//    NSParameterAssert([writer canAddInput:writerInput]);
//    
//    [writer addInput:writerInput];
    
    
    CGSize frameSize = CGSizeMake(380, 480);
    
    
    
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  self.outputVideoFileURL fileType:AVFileTypeAppleM4V
                                                              error:&error];
    
    if(error) {
        NSLog(@"error creating AssetWriter: %@",[error description]);
    }
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                   nil];
    
    
    
    AVAssetWriterInput* writerInput = [[AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings] retain];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    [attributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGImageCompatibilityKey];
    [attributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey];
    
    self.assetWriterPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:attributes];
    [videoWriter addInput:writerInput];
    
    // fixes all errors
    writerInput.expectsMediaDataInRealTime = YES;
    
    return [videoWriter autorelease];
}

- (IBAction)playVideo:(id)sender {
//    AVAssetWriter *writer = [self setupAssetWriter];
//    self.writer = writer;   
//    [self.writer startWriting];
//    [self.writer startSessionAtSourceTime:kCMTimeZero];
//    
//    [[self.assetReaders objectAtIndex:0] startReading];
//    [[self.assetReaders objectAtIndex:1] startReading];
//    AVAssetReaderOutput *output1 = [[[self.assetReaders objectAtIndex:0] outputs] objectAtIndex:0];
//    AVAssetReaderOutput *output2 = [[[self.assetReaders objectAtIndex:1] outputs] objectAtIndex:0];
//    UIImage *firstFrame = nil;
//    UIImage *secondFrame = nil;
//    while ([[self.assetReaders objectAtIndex:0] status] == AVAssetReaderStatusReading) {
//        CMSampleBufferRef sampleBuffer1 = [output1 copyNextSampleBuffer];
//        
//        if (sampleBuffer1 != NULL) {
//            firstFrame = [self imageFromCMSampleBuffer:sampleBuffer1];
//        } else {
//            break;
//        }
//        
//        while ([[self.assetReaders objectAtIndex:1] status] == AVAssetReaderStatusReading) {
//            CMSampleBufferRef sampleBuffer2 = [output2 copyNextSampleBuffer];
//            CMTime time2 = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer2);
//            NSLog(@"First video: %lld, %d", time2.value, time2.timescale);
//            if (sampleBuffer2 != NULL) {
//                secondFrame = [self imageFromCMSampleBuffer:sampleBuffer2];
//                [self drawFrame:@[firstFrame, secondFrame]];
//            } else {
//                break;
//            }
//        }
//        CMTime time1 = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer1);
//        NSLog(@"Second video: %lld, %d", time1.value, time1.timescale);
//        [self drawFrame:@[firstFrame]];
//    }
//    
//    [[[[self writer] inputs] objectAtIndex:0] markAsFinished];
//    [[self writer] finishWriting];
    
    NSString *videoSamplePath = [[NSBundle mainBundle] pathForResource:@"videoSample" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:videoSamplePath];
    
    [self resizeVideo:url outputPath:self.outputVideoFileURL];
}

- (void)drawFrame:(NSArray *)videoFrames {

//     CGRect videoRect = CGRectMake(0, 0, 200, 400);
//    
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef portraitContext = CGBitmapContextCreate(NULL,
//                                                         videoRect.size.width,
//                                                         videoRect.size.height,
//                                                         8,
//                                                         0,
//                                                         colorSpace,
//                                                         kCGImageAlphaNoneSkipFirst);
//    // Draw background
//    //
//    CGContextSetRGBFillColor(portraitContext,
//                             (CGFloat)0.0,
//                             (CGFloat)0.0,
//                             (CGFloat)0.0,
//                             (CGFloat)1.0);
//    CGContextFillRect(portraitContext, videoRect);
//   
//
//    CGRect rect = CGRectMake(10, 10, 100, 100);
//    // Draw video frame
//    for (UIImage *frame in videoFrames) {
//        CGContextDrawImage(portraitContext, rect, [frame CGImage]);
//        rect.origin.y += frame.size.height + 20;
//    }
    
    // Get final frame
    //
//    CGImageRef cgPortraitImage = CGBitmapContextCreateImage(portraitContext);
//    [self saveImage:[UIImage imageWithCGImage:cgPortraitImage]];
//    CVPixelBufferRef pixelBufer = [self pixelBufferFromCGImage:cgPortraitImage];
//    
//    [self pixelBufferFromCGImage:[first CGImage]]
//    
//    
//    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBufer];
//    
//    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
//    CGImageRef videoImage = [temporaryContext
//                             createCGImage:ciImage
//                             fromRect:CGRectMake(0, 0,
//                                                 CVPixelBufferGetWidth(pixelBufer),
//                                                 CVPixelBufferGetHeight(pixelBufer))];
//    
//    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
//    [self saveImage:uiImage];
    
    UIImage *image = [videoFrames objectAtIndex:0];
    
   CVPixelBufferRef buffer = [self pixelBufferFromCGImage:[image CGImage]];

    [self newFrameReady:buffer];
//    CGImageRelease(cgPortraitImage);
//    
//    CGColorSpaceRelease(colorSpace);
//    CGContextRelease(portraitContext);
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image {
    
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer (kCFAllocatorDefault, [self.assetWriterPixelBufferAdaptor pixelBufferPool], &pxbuffer);
    if (status != kCVReturnSuccess){
        NSLog(@"Failed to create pixel buffer");
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 CGImageGetWidth(image),
                                                 CGImageGetHeight(image),
                                                 CGImageGetBitsPerComponent(image),
                                                 CGImageGetBytesPerRow(image),
                                                 rgbColorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                                 CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


- (void)newFrameReady:(CVPixelBufferRef)pixelBuffer {
    CMTime frameTime = self.frameTime;
    
    if (![[[[self writer] inputs] objectAtIndex:0] isReadyForMoreMediaData]) {
        return;
    }
    

    BOOL result = [self.assetWriterPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:frameTime];
    
    if (result == NO) //failes on 3GS, but works on iphone 4
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
    
    /*We display the result on the custom layer*/
    /*self.customLayer.contents = (id) newImage;*/
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
    UIImage *image = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationUp];
        
    /*We relase the CGImageRef*/
    CGImageRelease(newImage);
    
    return image;
}

- (void)saveImage:(UIImage *)image {
    [UIImagePNGRepresentation(image) writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"image%ld.png", (long)counter++]] atomically:YES];
}

- (AVAssetReader *)setupReader:(AVAsset * )asset {
    NSError *error = nil;
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] , kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                   outputSettings:videoSettings];
    if ([assetReader canAddOutput:assetReaderOutput]) {
        [assetReader addOutput:assetReaderOutput];
    }
    return [assetReader autorelease];
}

@end
