#import "AIRGoogleMapBadgeMarker.h"
#import <React/RCTImageLoader.h>
#import <React/RCTUtils.h>

CIContext* g_ciContext;

@implementation AIRGoogleMapBadgeMarker {
  RCTImageLoaderCancellationBlock _imageCancellationBlock;
  RCTImageLoaderCancellationBlock _maskCancellationBlock;
  RCTImageLoaderCancellationBlock _overlayCancellationBlock;
  UIImage* _image;
  UIImage* _mask;
  UIImage* _overlay;
  UIImage* _currentIcon;
  CIImage* _ciOverlay;
  BOOL _isValid;
}

+ (CIContext*)ciContext {
  if (!g_ciContext)
    g_ciContext = [CIContext context];
  return g_ciContext;
}

- (instancetype)init {
  if ((self = [super init])) {
    _realMarker = [[AIRGMSMarker alloc] init];
    _realMarker.opacity = 0;
    _size = CGSizeMake(64, 64);
    _badgeScale = 1.0f;
    _isValid = YES;
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
                                                scale:1
                                              clipped:YES
                                           resizeMode:RCTResizeModeCenter
                                        progressBlock:nil
                                     partialLoadBlock:nil
                                      completionBlock:complete];
  
}

- (UIImage*)maskImage:(UIImage*)source mask:(UIImage*)mask {
  if (!_ciOverlay)
    return nil;
  
  CIImage* ciSource = [CIImage imageWithCGImage:source.CGImage];
  CIImage* ciMask = [CIImage imageWithCGImage:mask.CGImage];
  CIImage* ciBackground = [[CIImage imageWithColor:[CIColor clearColor]] imageByCroppingToRect:CGRectMake(0, 0, source.size.width, source.size.height)];
  
  CIContext* context = [AIRGoogleMapBadgeMarker ciContext];
  
  CIFilter* badgeFilter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"
                               withInputParameters:@{
                                                     @"inputImage": ciSource,
                                                     @"inputBackgroundImage": ciBackground,
                                                     @"inputMaskImage": ciMask
                                                     }];
  
  CIImage* badgeImage;
  if (_fadeBadgeImage)
    badgeImage = [badgeFilter.outputImage imageByApplyingFilter:@"CIColorControls"
                                            withInputParameters:@{
                                                                  @"inputSaturation": @(1.0),
                                                                  @"inputBrightness": @(0.4),
                                                                  @"inputContrast": @(1.0)
                                                                  }];
  else
    badgeImage = badgeFilter.outputImage;
  
  CIFilter* finalFilter = [CIFilter filterWithName:@"CISourceOverCompositing"
                               withInputParameters:@{
                                                     @"inputImage": _ciOverlay,
                                                     @"inputBackgroundImage": badgeImage
                                                     }];
  
  CIImage* final = finalFilter.outputImage;
  
  _isValid = YES;
  
  return [UIImage imageWithCGImage:[context createCGImage:final fromRect:final.extent]
                             scale:RCTScreenScale()
                       orientation:source.imageOrientation];
}

- (void)updateOverlay {
  if (!_overlay) {
    _ciOverlay = nil;
    return;
  }
  
  CGRect overlayRect = CGRectMake(0, 0, _overlay.size.width, _overlay.size.height);
  
  CIImage* ciBlank = [[CIImage imageWithColor:[CIColor clearColor]] imageByCroppingToRect:overlayRect];
  CIImage* ciColor = [[CIImage imageWithColor:[CIColor colorWithCGColor:_pinColor.CGColor]] imageByCroppingToRect:overlayRect];
  CIImage* ciOverlay = [CIImage imageWithCGImage:_overlay.CGImage];
  
  CIFilter* overlayFilter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"
                                 withInputParameters:@{
                                                       @"inputImage": ciColor,
                                                       @"inputBackgroundImage": ciBlank,
                                                       @"inputMaskImage": ciOverlay
                                                       }];
  _ciOverlay = overlayFilter.outputImage;
}

- (void)assignIcon {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (_currentIcon) {
      _realMarker.icon = [UIImage imageWithCGImage:_currentIcon.CGImage
                                             scale:_currentIcon.scale / _badgeScale
                                       orientation:_currentIcon.imageOrientation];
      _realMarker.opacity = 1;
      _realMarker.groundAnchor = CGPointMake(0.5f, 1.0f);
    } else {
      _realMarker.opacity = 0;
    }
  });
}

- (void)makeIcon {
  _currentIcon = nil;
  
  if (_image && _mask && _overlay)
    _currentIcon = [self maskImage:_image mask:_mask];
  
  [self assignIcon];
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
  
  if (!_overlay) {
    [self loadImage:_badgeOverlay cancel:_maskCancellationBlock complete:^(NSError *error, UIImage *image) {
      if (!error) {
        _overlay = image;
        [self updateOverlay];
        [self makeIcon];
      }
    }];
  }
  
  if (!_isValid)
    [self makeIcon];
}

- (void)setPinColor:(UIColor*)pinColor {
  _pinColor = pinColor;
  [self updateOverlay];
  [self updateIcon];
}

- (void)setSize:(CGSize)size {
  _size = size;
  _image = nil;
  _mask = nil;
  _overlay = nil;
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

- (void)setBadgeOverlay:(NSString*)badgeOverlay {
  _overlay = nil;
  _badgeOverlay = badgeOverlay;
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

- (void)setOnPress:(RCTBubblingEventBlock)onPress {
  _realMarker.onPress = onPress;
}

- (RCTBubblingEventBlock)onPress {
  return _realMarker.onPress;
}

- (void)setBadgeScale:(CGFloat)badgeScale {
  _badgeScale = badgeScale;
  [self assignIcon];
}

- (void)setFadeBadgeImage:(BOOL)fadeBadgeImage {
  _fadeBadgeImage = fadeBadgeImage;
  _isValid = NO;
  [self updateIcon];
}

@end
