#import "AIRGoogleMapBadgeMarker.h"
#import <React/RCTImageLoader.h>
#import <React/RCTUtils.h>

@implementation AIRGoogleMapBadgeMarker {
  RCTImageLoaderCancellationBlock _imageCancellationBlock;
  RCTImageLoaderCancellationBlock _maskCancellationBlock;
  UIImage* _image;
  UIImage* _mask;
}

- (instancetype)init {
  if ((self = [super init])) {
    _realMarker = [[AIRGMSMarker alloc] init];
    _realMarker.opacity = 0;
    _size = CGSizeMake(64, 64);
  }
  return self;
}

- (RCTImageLoaderCancellationBlock)loadImage:(NSString*)source
                                      cancel:(RCTImageLoaderCancellationBlock)cancel
                                    complete:(RCTImageLoaderCompletionBlock)complete {
  
  if (cancel) {
    cancel();
  }

  if (!source) {
    complete(nil, nil);
    return nil;
  }
  
  return [_bridge.imageLoader loadImageWithURLRequest:[RCTConvert NSURLRequest:source]
                                                 size:_size
                                                   scale:RCTScreenScale()
                                                 clipped:YES
                                              resizeMode:RCTResizeModeCenter
                                           progressBlock:nil
                                        partialLoadBlock:nil
                                         completionBlock:complete];
  
}

CGImageRef CopyImageAndAddAlphaChannel(CGImageRef sourceImage) {
  
  CGImageRef retVal = NULL;
  
  size_t width = CGImageGetWidth(sourceImage);
  
  size_t height = CGImageGetHeight(sourceImage);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  CGContextRef offscreenContext = CGBitmapContextCreate(NULL, width, height,
                                                        
                                                        8, 0, colorSpace,   kCGImageAlphaPremultipliedLast );
  
  
  if (offscreenContext != NULL) {
    
    CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), sourceImage);
    
    retVal = CGBitmapContextCreateImage(offscreenContext);
    
    CGContextRelease(offscreenContext);
    
  }
  
  CGColorSpaceRelease(colorSpace);
  
  return retVal;
  
}

- (UIImage*)invertImage:(UIImage *)sourceImage {
  CIContext *context = [CIContext contextWithOptions:nil];
  CIFilter *filter= [CIFilter filterWithName:@"CIColorInvert"];
  CIImage *inputImage = [[CIImage alloc] initWithImage:sourceImage];
  [filter setValue:inputImage forKey:@"inputImage"];
  return [UIImage imageWithCGImage:[context createCGImage:filter.outputImage fromRect:filter.outputImage.extent]];
  
}

- (UIImage*)maskImage:(UIImage*)source mask:(UIImage*)maskImage {
//  NSLog(@"source size %f %f, mask size %f %f", source.size.width, source.size.height, maskImage.size.width, maskImage.size.height);

  CGImageRef maskRef = maskImage.CGImage;
  
  CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                      CGImageGetHeight(maskRef),
                                      CGImageGetBitsPerComponent(maskRef),
                                      CGImageGetBitsPerPixel(maskRef),
                                      CGImageGetBytesPerRow(maskRef),
                                      CGImageGetDataProvider(maskRef), NULL, YES);
  
  CGImageRef sourceImage = [source CGImage];
  CGImageRef imageWithAlpha = sourceImage;

  if ((CGImageGetAlphaInfo(sourceImage) == kCGImageAlphaNone)
      || (CGImageGetAlphaInfo(sourceImage) == kCGImageAlphaNoneSkipFirst)
      || (CGImageGetAlphaInfo(sourceImage) == kCGImageAlphaNoneSkipLast)) {
    imageWithAlpha = CopyImageAndAddAlphaChannel(sourceImage);
  }
  
  CGImageRef masked = CGImageCreateWithMask(imageWithAlpha, mask);

  CGContextRef context = CGBitmapContextCreate(nil,
                                               CGImageGetWidth(imageWithAlpha),
                                               CGImageGetHeight(imageWithAlpha),
                                               CGImageGetBitsPerComponent(imageWithAlpha),
                                               CGImageGetBytesPerRow(imageWithAlpha),
                                               CGImageGetColorSpace(imageWithAlpha),
                                               CGImageGetBitmapInfo(imageWithAlpha));
  
  CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(imageWithAlpha), CGImageGetHeight(imageWithAlpha));
  CGContextDrawImage(context, imageRect, masked);
  CGImageRef maskedImageRef = CGBitmapContextCreateImage(context);
  UIImage* maskedImage = [UIImage imageWithCGImage:maskedImageRef];
  
  CGImageRelease(mask);
  CGContextRelease(context);
  CGImageRelease(maskedImageRef);
  CGImageRelease(masked);
  if (sourceImage != imageWithAlpha)
    CGImageRelease(imageWithAlpha);
  
  return maskedImage;
}

- (void)makeIcon {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIImage* icon = _image;
    
    if (_image && _mask) {
      icon = [self maskImage:_image mask:_mask];
//      NSLog(@"masked icon size %f %f", icon.size.width, icon.size.height);
    }
    
    _realMarker.icon = icon;
    if (_realMarker.icon)
      _realMarker.opacity = 1;
  });
}


- (void)updateIcon {
  if (!_image) {
    [self loadImage:_badgeImage cancel:_imageCancellationBlock complete:^(NSError *error, UIImage *image) {
      if (!error) {
        _image = image;
        [self makeIcon];
      }
    }];
  }
  
  if (!_mask) {
    [self loadImage:_badgeMask cancel:_maskCancellationBlock complete:^(NSError *error, UIImage *image) {
      if (!error) {
        _mask = image;
        [self makeIcon];
      }
    }];
  }
}

- (void)setPinColor:(UIColor*)pinColor {
  _pinColor = pinColor;
  [self updateIcon];
}

- (void)setSize:(CGSize)size {
  _size = size;
  _image = nil;
  _mask = nil;
  [self updateIcon];
}

- (void)setBadgeImage:(NSString*)badgeImage {
  _image = nil;
  _badgeImage = badgeImage;
  [self updateIcon];
}

- (void)setBadgeMask:(NSString*)badgeMask {
  _mask = nil;
  _badgeMask = badgeMask;
  [self updateIcon];
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
  _realMarker.position = coordinate;
}

- (CLLocationCoordinate2D)coordinate {
  return _realMarker.position;
}

- (void)setZIndex:(NSInteger)zIndex {
  _realMarker.zIndex = (int)zIndex;
}

- (NSInteger)zIndex {
  return _realMarker.zIndex;
}

@end
