package com.airbnb.android.react.maps;

import android.graphics.Color;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.Map;

import javax.annotation.Nullable;

public class AirMapBadgeMarkerManager extends ViewGroupManager<AirMapBadgeMarker> {
    public AirMapBadgeMarkerManager() { }

    @Override
    public String getName() {
        return "AIRMapBadgeMarker";
    }

    @Override
    public AirMapBadgeMarker createViewInstance(ThemedReactContext context) {
        return new AirMapBadgeMarker(context);
    }

    @ReactProp(name = "coordinate")
    public void setCoordinate(AirMapBadgeMarker view, ReadableMap map) {
        view.setCoordinate(map);
    }

    @Override
    @ReactProp(name = "zIndex", defaultFloat = 0.0f)
    public void setZIndex(AirMapBadgeMarker view, float zIndex) {
        super.setZIndex(view, zIndex);
        int integerZIndex = Math.round(zIndex);
        view.setZIndex(integerZIndex);
    }

    @ReactProp(name = "pinColor", defaultInt = Color.RED, customType = "Color")
    public void setPinColor(AirMapBadgeMarker view, int pinColor) {
        view.setPinColor(pinColor);
    }


    @ReactProp(name = "anchor")
    public void setAnchor(AirMapBadgeMarker view, ReadableMap map) {
        double x = map != null && map.hasKey("x") ? map.getDouble("x") : 0.5;
        double y = map != null && map.hasKey("y") ? map.getDouble("y") : 1.0;
        view.setAnchor(x, y);
    }

    @ReactProp(name = "badgeImage")
    public void setBadgeImage(AirMapBadgeMarker view, @Nullable  String badgeImage) {
        view.setBadgeImage(badgeImage);
    }

    @ReactProp(name = "badgeMask")
    public void setBadgeMask(AirMapBadgeMarker view, @Nullable String badgeMask) {
        view.setBadgeMask(badgeMask);
    }

    @ReactProp(name = "badgeOverlay")
    public void setBadgeOverlay(AirMapBadgeMarker view, @Nullable String badgeOverlay) {
        view.setBadgeOverlay(badgeOverlay);
    }

    @ReactProp(name = "scale", defaultFloat = 1.0f)
    public void setScale(AirMapBadgeMarker view, float scale) {
        view.setScale(scale);
    }

    @ReactProp(name = "size")
    public void setSize(AirMapBadgeMarker view, ReadableMap size) {
        double width = size != null && size.hasKey("width") ? size.getDouble("width") : 64;
        double height = size != null && size.hasKey("height") ? size.getDouble("height") : 64;
        view.setSize(width, height);
    }

    @ReactProp(name = "fadeBadgeImage", defaultBoolean = true)
    public void setFadeBadgeImage(AirMapBadgeMarker view, boolean fadeBadgeImage) {
        view.setFadeBadgeImage(fadeBadgeImage);
    }


    @Override
    @Nullable
    public Map getExportedCustomDirectEventTypeConstants() {
        Map<String, Map<String, String>> map = MapBuilder.of(
                "onPress", MapBuilder.of("registrationName", "onPress")
        );
        return map;
    }
}
