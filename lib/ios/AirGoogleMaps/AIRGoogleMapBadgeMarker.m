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
  CIImage* _ciOverlay;
  
  UIImage* _currentIcon;
  UIImage* _currentImage;
  UIImage* _currentMask;
  UIImage* _currentOverlay;
  UIColor* _currentPinColor;
  CGSize _currentSize;
  CGFloat _currentBadgeScale;
  BOOL _currentFadeBadgeImage;
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

- (UIImage*)maskImage:(UIImage*)source mask:(UIImage*)mask {
  if (!_ciOverlay)
    return nil;
  
  CIImage* ciSource = [CIImage imageWithCGImage:source.CGImage];
  CIImage* ciMask = [CIImage imageWithCGImage:mask.CGImage];
  CIImage* ciBackground = [[CIImage imageWithColor:[CIColor clearColor]]
                           imageByCroppingToRect:CGRectMake(0, 0, source.size.width * source.scale, source.size.height * source.scale)
                           ];
  
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
  
  return [UIImage imageWithCGImage:[context createCGImage:final fromRect:final.extent]
                             scale:source.scale
                       orientation:source.imageOrientation];
}

- (void)updateOverlay {
  if (!_overlay) {
    _ciOverlay = nil;
    return;
  }
  
  CGRect overlayRect = CGRectMake(0, 0, _overlay.size.width * _overlay.scale, _overlay.size.height * _overlay.scale);
  
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
    if (_currentIcon && (_badgeScale != _currentBadgeScale)) {
      if (_currentIcon) {
        _realMarker.icon = [UIImage imageWithCGImage:_currentIcon.CGImage
                                               scale:_currentIcon.scale / _badgeScale
                                         orientation:_currentIcon.imageOrientation];
        _realMarker.opacity = 1;
        _realMarker.appearAnimation = kGMSMarkerAnimationNone;
        _currentBadgeScale = _badgeScale;
      } else {
        if (_realMarker.icon)
          _realMarker.icon = nil;
        _realMarker.opacity = 0;
        _realMarker.appearAnimation = kGMSMarkerAnimationNone;
      }
    }
  });
}

- (BOOL)isValid {
  return(
         (_currentImage == _image) &&
         (_currentMask == _mask) &&
         (_currentOverlay == _overlay) &&
         (_currentPinColor == _pinColor) &&
         (_currentFadeBadgeImage == _fadeBadgeImage) &&
         CGSizeEqualToSize(_currentSize, _size)
         );
}

- (void)nowValid {
  _currentImage = _image;
  _currentMask = _mask;
  _currentOverlay = _overlay;
  _currentPinColor = _pinColor;
  _currentFadeBadgeImage = _fadeBadgeImage;
  _currentSize = _size;
}

- (void)makeIcon {
  @synchronized(_realMarker) {
    if (![self isValid]) {
      if (_image && _mask && _overlay) {
        [self updateOverlay];
        _currentIcon = [self maskImage:_image mask:_mask];
        [self assignIcon];
        [self nowValid];
      } else {
        _currentIcon = nil;
        [self assignIcon];
      }
    }
  }
}

- (void)updateIcon {
  if (!_image) {
    _imageCancellationBlock = [self loadImage:_badgeImage
                                       cancel:_imageCancellationBlock
                                     complete:^(NSError *error, UIImage *image) {
                                       _imageCancellationBlock = nil;
                                       if (!error) {
                                         _image = image;
                                         [self makeIcon];
                                       }
                                     }];
  }
  
  if (!_mask) {
    _maskCancellationBlock = [self loadImage:_badgeMask
                                      cancel:_maskCancellationBlock
                                    complete:^(NSError *error, UIImage *image) {
                                      _maskCancellationBlock = nil;
                                      if (!error) {
                                        _mask = image;
                                        [self makeIcon];
                                      }
                                    }];
  }
  
  if (!_overlay) {
    _overlayCancellationBlock = [self loadImage:_badgeOverlay
                                         cancel:_overlayCancellationBlock
                                       complete:^(NSError *error, UIImage *image) {
                                         _overlayCancellationBlock = nil;
                                         if (!error) {
                                           _overlay = image;
                                           [self makeIcon];
                                         }
                                       }];
  }
  [self makeIcon];
}

- (void)setPinColor:(UIColor*)pinColor {
  _pinColor = pinColor;
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

- (void)setBadgeScale:(CGFloat)badgeScale {
  _badgeScale = badgeScale;
  [self assignIcon];
}

- (void)setFadeBadgeImage:(BOOL)fadeBadgeImage {
  _fadeBadgeImage = fadeBadgeImage;
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

- (void)setAnchor:(CGPoint)anchor {
  _realMarker.groundAnchor = CGPointMake(0.5f, 0.5f);
}

- (CGPoint)anchor {
  return _realMarker.groundAnchor;
}

@end
