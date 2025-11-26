import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/map_view_widget.dart';
import '../../services/location/location_service.dart';
import '../../services/friends/friends_service.dart';
import '../../models/friend.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final FriendsService _friendsService = FriendsService();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  List<Friend> _friends = [];
  bool _isLoading = true;
  String? _error;
  MapViewController? _mapController;

  @override
  void initState() {
    super.initState();
    _initializeMap();
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

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadFriendsLocations();
  }

  Future<void> _loadFriendsLocations() async {
    try {
      final friends = await _friendsService.getFriendsLocations();
      setState(() {
        _friends = friends;
        _createMarkers();
      });
    } catch (e) {
      debugPrint('Error loading friends locations: $e');
      // Don't show error for friends locations, just continue without them
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    // Add current user marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Your current location',
          ),
        ),
      );
    }

    // Add friends markers
    for (final friend in _friends) {
      final position = LatLng(friend.latitude, friend.longitude);
      
      // Choose marker color based on availability status
      double hue = BitmapDescriptor.hueGreen; // Default: available
      if (friend.availabilityStatus == 'busy') {
        hue = BitmapDescriptor.hueRed;
      } else if (friend.availabilityStatus == 'away') {
        hue = BitmapDescriptor.hueOrange;
      }

      markers.add(
        Marker(
          markerId: MarkerId('friend_${friend.userId}'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: friend.fullName,
            snippet: '${friend.availabilityStatus.toUpperCase()} • ${_formatLastSeen(friend.updatedAt)}',
          ),
          onTap: () => _onFriendMarkerTap(friend),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  String _formatLastSeen(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _onFriendMarkerTap(Friend friend) {
    // TODO: Show friend details or options (message, meet up, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped on ${friend.fullName}'),
        duration: const Duration(seconds: 2),
      ),
    );
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

