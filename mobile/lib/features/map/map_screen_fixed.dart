import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/map_view_widget.dart';
import 'widgets/friend_map_bottom_sheet.dart';
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
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    await _getCurrentLocation();
    await _loadFriendsLocations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _updateMarkers();
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
    try {
      final friends = await _friendsService.getFriendsLocations();
      setState(() {
        _friends = friends;
      });
      _updateMarkers();
    } catch (e) {
      debugPrint('Error loading friends locations: $e');
      setState(() {
        _error = 'Error getting friends locations: $e';
      });
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};

    // Add current user marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add friend markers
    for (final friend in _friends) {
      final position = LatLng(
        double.parse(friend.latitude),
        double.parse(friend.longitude),
      );

      double hue;
      switch (friend.availabilityStatus.toLowerCase()) {
        case 'available':
          hue = BitmapDescriptor.hueGreen;
          break;
        case 'busy':
          hue = BitmapDescriptor.hueRed;
          break;
        case 'away':
          hue = BitmapDescriptor.hueOrange;
          break;
        default:
          hue = BitmapDescriptor.hueViolet;
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
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FriendMapBottomSheet(friend: friend),
            );
          },
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

  void _showAllFriends() {
    if (_friends.isEmpty || _mapController == null) return;

    // Calculate bounds to show all friends
    double minLat = _friends.first.latitude;
    double maxLat = _friends.first.latitude;
    double minLng = _friends.first.longitude;
    double maxLng = _friends.first.longitude;

    for (final friend in _friends) {
      minLat = minLat < friend.latitude ? minLat : friend.latitude;
      maxLat = maxLat > friend.latitude ? maxLat : friend.latitude;
      minLng = minLng < friend.longitude ? minLng : friend.longitude;
      maxLng = maxLng > friend.longitude ? maxLng : friend.longitude;
    }

    // Include current position if available
    if (_currentPosition != null) {
      minLat = minLat < _currentPosition!.latitude ? minLat : _currentPosition!.latitude;
      maxLat = maxLat > _currentPosition!.latitude ? maxLat : _currentPosition!.latitude;
      minLng = minLng < _currentPosition!.longitude ? minLng : _currentPosition!.longitude;
      maxLng = maxLng > _currentPosition!.longitude ? maxLng : _currentPosition!.longitude;
    }

    // Calculate center and zoom to show all friends
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    _mapController!.animateToPosition(
      LatLng(centerLat, centerLng),
      zoom: 12.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
                          onPressed: _initializeMapData,
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
        
        // Floating action buttons
        if (!_isLoading && _error == null && _currentPosition != null) ...[
          // My location button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: "my_location",
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
          
          // Friends toggle button
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: "friends_toggle",
              backgroundColor: _friends.isNotEmpty 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey,
              onPressed: () {
                if (_friends.isNotEmpty) {
                  _showAllFriends();
                }
              },
              child: Badge(
                label: Text('${_friends.length}'),
                child: const Icon(Icons.people),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
