#import <GoogleMaps/GoogleMaps.h>
#import <React/RCTBridge.h>
#import "AIRGMSMarker.h"
#import "AIRGoogleMap.h"
#import "AIRGoogleMapCallout.h"

@interface AIRGoogleMapBadgeMarker : UIView

@property (nonatomic, weak) RCTBridge* bridge;
@property (nonatomic, strong) AIRGMSMarker* realMarker;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) UIColor* pinColor;
@property (nonatomic, assign) NSInteger zIndex;
@property (nonatomic, copy) RCTBubblingEventBlock onPress;

@property (nonatomic, copy) NSString* badgeImage;
@property (nonatomic, copy) NSString* badgeMask;
@property (nonatomic, copy) NSString* badgeOverlay;
@property (nonatomic, assign) BOOL fadeBadgeImage;
@property (nonatomic, assign) CGFloat badgeScale;
@property (nonatomic, assign) CGSize size;


@end
