import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/map_config.dart';

class MapViewWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final Set<Marker>? markers;
  final Function(LatLng)? onMapTap;
  final Function(CameraPosition)? onCameraMove;
  final Function(MapViewController)? onMapCreated;

  const MapViewWidget({
    super.key,
    this.initialPosition,
    this.markers,
    this.onMapTap,
    this.onCameraMove,
    this.onMapCreated,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

// Public controller to access map methods
class MapViewController {
  _MapViewWidgetState? _state;

  void _attach(_MapViewWidgetState state) {
    _state = state;
  }

  Future<void> animateToPosition(LatLng position, {double zoom = 14.0}) async {
    await _state?.animateToPosition(position, zoom: zoom);
  }
}

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  MapViewController? _publicController;

  @override
  void initState() {
    super.initState();
    _publicController = MapViewController();
    _publicController?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Notify parent when controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated?.call(_publicController!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: widget.initialPosition != null
          ? CameraPosition(
              target: widget.initialPosition!,
              zoom: 14.0,
            )
          : MapConfig.defaultCameraPosition,
      markers: widget.markers ?? {},
            myLocationEnabled: false, // Disable default location marker
            myLocationButtonEnabled: false, // Disable default button
      mapType: MapType.normal,
      zoomControlsEnabled: false, // We'll use custom controls
      compassEnabled: false, // Disable compass
      mapToolbarEnabled: false, // Disable toolbar (includes logo controls)
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Apply custom map style to hide Google logo and other UI elements
        _applyMapStyle(controller);
      },
      onTap: (LatLng position) {
        widget.onMapTap?.call(position);
      },
      onCameraMove: (CameraPosition position) {
        widget.onCameraMove?.call(position);
      },
    );
  }

  void _applyMapStyle(GoogleMapController controller) async {
    // Custom map style to hide Google logo and other UI elements
    const String mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "poi.business",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    ''';
    
    try {
      await controller.setMapStyle(mapStyle);
    } catch (e) {
      // If style fails to apply, continue without it
      debugPrint('Error applying map style: $e');
    }
  }

  // Method to move camera to a specific position
  Future<void> animateToPosition(LatLng position, {double zoom = 14.0}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: zoom),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

