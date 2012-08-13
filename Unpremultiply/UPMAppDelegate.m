//
//  UPMAppDelegate.m
//  Unpremultiply
//
//  Created by James Montgomerie on 13/08/2012.
//  Copyright (c) 2012 James Montgomerie. All rights reserved.
//

#import "UPMAppDelegate.h"

@implementation UPMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp setServicesProvider:self];
}

- (void)unpremultiply:(NSPasteboard *)pasteboard
             userData:(NSDictionary *)userData
                error:(NSString * __autoreleasing *)error
{
    NSArray *arrayOfURLs = [pasteboard readObjectsForClasses:@[ [NSURL class] ]
                                                     options:@{ NSPasteboardURLReadingFileURLsOnlyKey : @YES }];
    
    for(NSURL *URL in arrayOfURLs) {
        [self unpremultiplyFileWithURL:URL];
    }
}

- (void)unpremultiplyFileWithURL:(NSURL *)filePathURL
{
    NSString *path = [[filePathURL filePathURL] path];
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)filePathURL, NULL);
    if(imageSource) {
        CGImageRef premultipliedImage  = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CFRelease(imageSource);
        
        if(premultipliedImage) {
            CGImageRef unpremultipliedImage = [self newUnpremultipliedImageWithImage:premultipliedImage];
            CFRelease(premultipliedImage);
            if(unpremultipliedImage) {
                NSString *extension = [path pathExtension];
                NSString *noExtension = [path stringByDeletingPathExtension];
                
                NSString *newPath = [[noExtension stringByAppendingPathExtension:@"unpremultipled"] stringByAppendingPathExtension:extension];
                
                CGImageDestinationRef pngDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:newPath],
                                                                                       kUTTypePNG, 1, NULL);
                CGImageDestinationAddImage(pngDestination, unpremultipliedImage, NULL);
                CGImageDestinationFinalize(pngDestination);
                CFRelease(pngDestination);
                
                CFRelease(unpremultipliedImage);
            }
        }
    }
}

static void CGBitmapContextReleaseCFTypeRefCallback(void *releaseInfo, void *data)
{
    CFRelease(releaseInfo);
}

- (CGImageRef)newUnpremultipliedImageWithImage:(CGImageRef)image
{
    CGImageRef unpremltipliedImage = NULL;
    
    CGColorSpaceRef imageColorSpace = CGImageGetColorSpace(image);
    if(imageColorSpace) {
        CFRetain(imageColorSpace);
    } else {
        imageColorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    BOOL goodBitmapInfo = NO;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image);
    if((bitmapInfo & kCGImageAlphaLast) == kCGImageAlphaLast) {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedLast;
        goodBitmapInfo = YES;
    } else if((bitmapInfo & kCGImageAlphaFirst) == kCGImageAlphaFirst) {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
        goodBitmapInfo = YES;
    } else {
        NSLog(@"Unexpected bitmap info alpha information - bitmap info is 0x%02lx - can't unpremultiply", (long)bitmapInfo);
    }
    
    if(goodBitmapInfo) {
        CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image));
        CGContextRef premultContext = CGBitmapContextCreateWithData((void *)CFDataGetBytePtr(data),
                                                                    CGImageGetWidth(image), CGImageGetHeight(image),
                                                                    CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image),
                                                                    imageColorSpace, bitmapInfo,
                                                                    CGBitmapContextReleaseCFTypeRefCallback, (void *)CFRetain(data));
        
        unpremltipliedImage = CGBitmapContextCreateImage(premultContext);
        
        CFRelease(premultContext);
        CFRelease(data);
    }

    CFRelease(imageColorSpace);
    
    return unpremltipliedImage;
}

@end
