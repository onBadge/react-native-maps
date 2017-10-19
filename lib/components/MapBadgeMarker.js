import PropTypes from 'prop-types';
import React from 'react';
import {
  StyleSheet,
  Platform,
  NativeModules,
  Animated,
  findNodeHandle,
  ViewPropTypes,
} from 'react-native';

import resolveAssetSource from 'react-native/Libraries/Image/resolveAssetSource';
import decorateMapComponent, {
  SUPPORTED,
  USES_DEFAULT_IMPLEMENTATION,
} from './decorateMapComponent';

const viewConfig = {
  uiViewClassName: 'AIR<provider>MapBadgeMarker',
  validAttributes: {
    coordinate: true,
  },
};

const propTypes = {
  ...ViewPropTypes,

  badgeImage: PropTypes.any,
  badgeMask: PropTypes.any,
  badgeOverlay: PropTypes.any,
  pinColor: PropTypes.string,
  scale: PropTypes.number,
  fadeBadgeImage: PropTypes.bool,
  anchor: PropTypes.shape({
    x: PropTypes.number.isRequired,
    y: PropTypes.number.isRequired,
  }),
  size: PropTypes.shape({
      width: PropTypes.number.isRequired,
      height: PropTypes.number.isRequired,
  }),
  coordinate: PropTypes.shape({
    latitude: PropTypes.number.isRequired,
    longitude: PropTypes.number.isRequired,
  }).isRequired,
  onPress: PropTypes.func
};

const defaultProps = {
    size: { width: 64, height: 64 },
    scale: 1.0,
    achor: { x: 0.5, y: 0.5 },
    onPress() {},
};

class MapBadgeMarker extends React.Component {
  setNativeProps(props) {
    this.marker.setNativeProps(props);
  }

  _getHandle() {
    return findNodeHandle(this.marker);
  }

  render() {
    let badgeImage;
    if (this.props.badgeImage) {
        badgeImage = resolveAssetSource(this.props.badgeImage) || {};
        badgeImage = badgeImage.uri || this.props.badgeImage;
    }

    let badgeMask;
    if (this.props.badgeMask) {
        badgeMask = resolveAssetSource(this.props.badgeMask) || {};
        badgeMask = badgeMask.uri || this.props.badgeMask;
    }

    let badgeOverlay;
    if (this.props.badgeOverlay) {
        badgeOverlay = resolveAssetSource(this.props.badgeOverlay) || {};
        badgeOverlay = badgeOverlay.uri || this.props.badgeOverlay;
    }

    const AIRMapBadgeMarker = this.getAirComponent();

    return (
      <AIRMapBadgeMarker
        ref={ref => { this.marker = ref; }}
        {...this.props}
        badgeImage={badgeImage}
        badgeMask={badgeMask}
        badgeOverlay={badgeOverlay}
        style={[styles.marker, this.props.style]}
      />
    );
  }
}

MapBadgeMarker.propTypes = propTypes;
MapBadgeMarker.viewConfig = viewConfig;

const styles = StyleSheet.create({
  marker: {
    position: 'absolute',
    backgroundColor: 'transparent',
  },
});

MapBadgeMarker.Animated = Animated.createAnimatedComponent(MapBadgeMarker);

module.exports = decorateMapComponent(MapBadgeMarker, {
  componentType: 'BadgeMarker',
  providers: {
    google: {
      ios: SUPPORTED,
      android: USES_DEFAULT_IMPLEMENTATION,
    },
  },
});
