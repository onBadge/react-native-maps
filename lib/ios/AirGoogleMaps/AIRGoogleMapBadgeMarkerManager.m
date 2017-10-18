#import "AIRGoogleMapBadgeMarkerManager.h"
#import "AIRGoogleMapBadgeMarker.h"
#import <MapKit/MapKit.h>
#import <React/RCTUIManager.h>
#import "RCTConvert+AirMap.h"

@implementation AIRGoogleMapBadgeMarkerManager

RCT_EXPORT_MODULE()

- (UIView*)view {
  AIRGoogleMapBadgeMarker* marker = [AIRGoogleMapBadgeMarker new];
  marker.bridge = self.bridge;
  return marker;
}

RCT_EXPORT_VIEW_PROPERTY(coordinate, CLLocationCoordinate2D)
RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(pinColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(zIndex, NSInteger)

RCT_EXPORT_VIEW_PROPERTY(badgeImage, NSString)
RCT_EXPORT_VIEW_PROPERTY(badgeMask, NSString)
RCT_EXPORT_VIEW_PROPERTY(badgeOverlay, NSString)
RCT_EXPORT_VIEW_PROPERTY(size, CGSize)

@end
