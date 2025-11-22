import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/map_config.dart';

class MapViewWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final Set<Marker>? markers;
  final Function(LatLng)? onMapTap;
  final Function(CameraPosition)? onCameraMove;

  const MapViewWidget({
    super.key,
    this.initialPosition,
    this.markers,
    this.onMapTap,
    this.onCameraMove,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;

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
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: false, // We'll use custom controls
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Apply custom map style if needed
        // controller.setMapStyle(MapConfig.mapStyle);
      },
      onTap: (LatLng position) {
        widget.onMapTap?.call(position);
      },
      onCameraMove: (CameraPosition position) {
        widget.onCameraMove?.call(position);
      },
    );
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

