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

- (UIImage*)maskImage:(UIImage*)source mask:(UIImage*)mask overlay:(UIImage*)overlay {
  CIImage* ciSource = [CIImage imageWithCGImage:source.CGImage];
  CIImage* ciMask = [CIImage imageWithCGImage:mask.CGImage];
  CIImage* ciBackground = [[CIImage imageWithColor:[CIColor clearColor]] imageByCroppingToRect:CGRectMake(0, 0, source.size.width, source.size.height)];
  CIImage* ciOverlayBackground = [[CIImage imageWithColor:[CIColor colorWithCGColor:_pinColor.CGColor]] imageByCroppingToRect:CGRectMake(0, 0, source.size.width, source.size.height)];
  CIImage* ciOverlay = [CIImage imageWithCGImage:overlay.CGImage];
  
  CIContext* context = [AIRGoogleMapBadgeMarker ciContext];
  
  CIFilter* badgeFilter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"
                               withInputParameters:@{
                                                     @"inputImage": ciSource,
                                                     @"inputBackgroundImage": ciBackground,
                                                     @"inputMaskImage": ciMask
                                                     }];
  CIImage* badgeImage = [badgeFilter.outputImage imageByApplyingFilter:@"CIColorControls"
                                                   withInputParameters:@{
                                                                         @"inputSaturation": @(1.0),
                                                                         @"inputBrightness": @(0.4),
                                                                         @"inputContrast": @(1.0)
                                                                         }];
  
  
  CIFilter* overlayFilter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"
                                 withInputParameters:@{
                                                       @"inputImage": ciOverlayBackground,
                                                       @"inputBackgroundImage": ciBackground,
                                                       @"inputMaskImage": ciOverlay
                                                       }];
  
  CIFilter* finalFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
  [finalFilter setValue:overlayFilter.outputImage forKey:@"inputImage"];
  [finalFilter setValue:badgeImage forKey:@"inputBackgroundImage"];
  
  CIImage* final = finalFilter.outputImage;
  
  return [UIImage imageWithCGImage:[context createCGImage:final fromRect:final.extent]
                             scale:RCTScreenScale()
                       orientation:source.imageOrientation];
}

- (void)makeIcon {
  UIImage* icon = nil;
  
  if (_image && _mask && _overlay)
    icon = [self maskImage:_image mask:_mask overlay:_overlay];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    _realMarker.icon = icon;
    if (_realMarker.icon)
      _realMarker.opacity = 1;
    _realMarker.groundAnchor = CGPointMake(0.5f, 0.75f);
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
  
  if (!_overlay) {
    [self loadImage:_badgeOverlay cancel:_maskCancellationBlock complete:^(NSError *error, UIImage *image) {
      if (!error) {
        _overlay = image;
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

@end
