import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/map_view_widget.dart';
import '../../services/location/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  MapViewController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadFriendsLocations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not get current location';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriendsLocations() async {
    // TODO: Load friends locations from API
    // For now, we'll just show current user location
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full screen map
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _getCurrentLocation,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _currentPosition != null
                    ? MapViewWidget(
                        initialPosition: _currentPosition,
                        markers: _markers,
                        onMapCreated: (controller) {
                          setState(() {
                            _mapController = controller;
                          });
                        },
                      )
                    : const Center(
                        child: Text('No location available'),
                      ),
        // Floating action button for my location
        if (!_isLoading && _error == null && _currentPosition != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                if (_currentPosition != null && _mapController != null) {
                  _mapController!.animateToPosition(
                    _currentPosition!,
                    zoom: 15.0,
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }
}

