package com.airbnb.android.react.maps;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.drawable.Animatable;
import android.net.Uri;
import android.support.annotation.NonNull;

import com.facebook.common.references.CloseableReference;
import com.facebook.datasource.DataSource;
import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.drawee.backends.pipeline.PipelineDraweeController;
import com.facebook.drawee.controller.BaseControllerListener;
import com.facebook.drawee.controller.ControllerListener;
import com.facebook.drawee.drawable.ScalingUtils;
import com.facebook.drawee.generic.GenericDraweeHierarchy;
import com.facebook.drawee.generic.GenericDraweeHierarchyBuilder;
import com.facebook.drawee.interfaces.DraweeController;
import com.facebook.drawee.view.DraweeHolder;
import com.facebook.imagepipeline.core.ImagePipeline;
import com.facebook.imagepipeline.image.CloseableImage;
import com.facebook.imagepipeline.image.CloseableStaticBitmap;
import com.facebook.imagepipeline.image.ImageInfo;
import com.facebook.imagepipeline.request.ImageRequest;
import com.facebook.imagepipeline.request.ImageRequestBuilder;
import com.facebook.react.bridge.ReadableMap;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.model.BitmapDescriptor;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import javax.annotation.Nullable;

public class AirMapBadgeMarker extends AirMapFeature {
    private class ImageControllerListener extends BaseControllerListener<ImageInfo> {
        private AirMapBadgeMarker marker;
        private DataSource<CloseableReference<CloseableImage>> dataSource;
        private Bitmap bitmap;
        private BitmapDescriptor bitmapDescriptor;

        public BitmapDescriptor getBitmapDescriptor() {
            return this.bitmapDescriptor;
        }

        public Bitmap getBitmap() {
            return this.bitmap;
        }

        public ImageControllerListener(AirMapBadgeMarker marker, DataSource<CloseableReference<CloseableImage>> dataSource) {
            this.marker = marker;
            this.dataSource = dataSource;
            this.bitmapDescriptor = null;
        }

        @Override
        public void onFinalImageSet(
                String id,
                @Nullable final ImageInfo imageInfo,
                @Nullable Animatable animatable) {
            CloseableReference<CloseableImage> imageReference = null;
            try {
                imageReference = dataSource.getResult();
                if (imageReference != null) {
                    CloseableImage image = imageReference.get();
                    if (image != null && image instanceof CloseableStaticBitmap) {
                        CloseableStaticBitmap closeableStaticBitmap = (CloseableStaticBitmap) image;
                        Bitmap bitmap = closeableStaticBitmap.getUnderlyingBitmap();
                        if (bitmap != null) {
                            this.bitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true);
                            this.bitmapDescriptor = BitmapDescriptorFactory.fromBitmap(bitmap);
                        }
                    }
                }
            } finally {
                this.dataSource.close();
                if (imageReference != null) {
                    CloseableReference.closeSafely(imageReference);
                }
            }
            this.marker.imageLoaded();
        }
    }



    private MarkerOptions markerOptions;
    private Marker marker;

    private LatLng position;


    private final Context context;

    private int pinColor;

    private boolean anchorIsSet;
    private float anchorX;
    private float anchorY;
    private int zIndex = 0;
    private int width = 64;
    private int height = 64;
    private String badgeImage;
    private String badgeMask;
    private String badgeOverlay;
    private boolean fadeBadgeImage;
    private float scale = 1.0f;

    private BitmapDescriptor iconBitmapDescriptor;

    private DraweeHolder<?> badgeImageHolder;
    private DraweeHolder<?> badgeMaskHolder;
    private DraweeHolder<?> badgeOverlayHolder;
    private Map<DraweeHolder<?>, ImageControllerListener> controllerMap = new HashMap<>();

    public AirMapBadgeMarker(Context context) {
        super(context);
        this.context = context;
        badgeImageHolder = DraweeHolder.create(createDraweeHierarchy(), context);
        badgeImageHolder.onAttach();
        badgeMaskHolder = DraweeHolder.create(createDraweeHierarchy(), context);
        badgeMaskHolder.onAttach();
        badgeOverlayHolder = DraweeHolder.create(createDraweeHierarchy(), context);
        badgeOverlayHolder.onAttach();
    }

    private GenericDraweeHierarchy createDraweeHierarchy() {
        return new GenericDraweeHierarchyBuilder(getResources())
                .setActualImageScaleType(ScalingUtils.ScaleType.FIT_CENTER)
                .setFadeDuration(0)
                .build();
    }

    public MarkerOptions getMarkerOptions() {
        if (markerOptions == null)
            markerOptions = createMarkerOptions();
        return markerOptions;
    }

    @Override
    public Object getFeature() {
        return marker;
    }

    @Override
    public void addToMap(GoogleMap map) {
        marker = map.addMarker(getMarkerOptions());
    }

    @Override
    public void removeFromMap(GoogleMap map) {
        marker.remove();
        marker = null;
    }

    public void setCoordinate(ReadableMap coordinate) {
        position = new LatLng(coordinate.getDouble("latitude"), coordinate.getDouble("longitude"));
        if (marker != null)
            marker.setPosition(position);
    }

    public void setZIndex(int zIndex) {
        this.zIndex = zIndex;
        if (marker != null)
            marker.setZIndex(zIndex);
    }

    public void setPinColor(int pinColor) {
        this.pinColor = pinColor;
        update();
    }

    public void setAnchor(double x, double y) {
        anchorIsSet = true;
        anchorX = (float)x;
        anchorY = (float)y;
        if (marker != null)
            marker.setAnchor(anchorX, anchorY);
    }

    public void setSize(double width, double height) {
        this.width = (int)width;
        this.height = (int)height;
        update();
    }

    private void loadBitmap(String uri, DraweeHolder<?> holder) {
        ImageRequest imageRequest = ImageRequestBuilder
                .newBuilderWithSource(Uri.parse(uri))
                .build();

        ImagePipeline imagePipeline = Fresco.getImagePipeline();
        DataSource<CloseableReference<CloseableImage>> dataSource = imagePipeline.fetchDecodedImage(imageRequest, this);
        ImageControllerListener controllerListener = new ImageControllerListener(this, dataSource);
        DraweeController controller = Fresco.newDraweeControllerBuilder()
                .setImageRequest(imageRequest)
                .setControllerListener(controllerListener)
                .setOldController(holder.getController())
                .build();
        holder.setController(controller);
        this.controllerMap.put(holder, controllerListener);
    }

    public void setBadgeImage(String badgeImage) {
        this.badgeImage = badgeImage;
        this.loadBitmap(badgeImage, badgeImageHolder);
    }

    public void setBadgeMask(String badgeMask) {
        this.badgeMask = badgeMask;
        this.loadBitmap(badgeMask, badgeMaskHolder);
    }

    public void setBadgeOverlay(String badgeOverlay) {
        this.badgeOverlay = badgeOverlay;
        this.loadBitmap(badgeOverlay, badgeOverlayHolder);
    }

    public void setFadgeBadgeImage(boolean fadeBadgeImage) {
        this.fadeBadgeImage = fadeBadgeImage;
    }

    public void setScale(float scale) {
        this.scale = scale;
    }

    private BitmapDescriptor getIcon() {
        if (iconBitmapDescriptor != null) {
            // use local image as a marker
            return iconBitmapDescriptor;
        } else {
            // render the default marker pin
            return BitmapDescriptorFactory.defaultMarker(10);
        }
    }

    private MarkerOptions createMarkerOptions() {
        MarkerOptions options = new MarkerOptions().position(position);
        if (anchorIsSet)
            options.anchor(anchorX, anchorY);
        options.zIndex(zIndex);
        options.icon(getIcon());
        return options;
    }

    public void imageLoaded() {
        Bitmap image = null;
        Bitmap mask = null;
        Bitmap overlay = null;

        ImageControllerListener controllerListener = this.controllerMap.get(badgeImageHolder);
        if (controllerListener != null)
            image = controllerListener.getBitmap();

        controllerListener = this.controllerMap.get(badgeMaskHolder);
        if (controllerListener != null)
            mask = controllerListener.getBitmap();

        controllerListener = this.controllerMap.get(badgeOverlayHolder);
        if (controllerListener != null)
            overlay = controllerListener.getBitmap();

        if ((image != null) && (mask != null) && (overlay != null)) {
            Bitmap result = Bitmap.createBitmap(mask.getWidth(), mask.getHeight(), Bitmap.Config.ARGB_8888);
            Canvas tempCanvas = new Canvas(result);
            Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
            paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.DST_IN));
            tempCanvas.drawBitmap(image, 0, 0, null);
            tempCanvas.drawBitmap(mask, 0, 0, paint);
            paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_OVER));
            tempCanvas.drawBitmap(overlay, 0, 0, paint);

            iconBitmapDescriptor = BitmapDescriptorFactory.fromBitmap(result);
        } else {
            iconBitmapDescriptor = null;
        }
        update();
    }

    public void update() {
        if (marker == null)
            return;

        marker.setIcon(getIcon());
    }
}
