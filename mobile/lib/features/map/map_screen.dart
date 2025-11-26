import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'widgets/map_view_widget.dart';
import 'widgets/friend_info_popup.dart';
import 'widgets/custom_marker_generator.dart';
import '../../services/location/location_service.dart';
import '../../services/friends/friends_service.dart';
import '../../services/auth/auth_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh friends locations when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFriendsLocations();
      }
    });
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
        await _updateMarkers();
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
      await _updateMarkers();
    } catch (e) {
      debugPrint('Error loading friends locations: $e');
      setState(() {
        _error = 'Error getting friends locations: $e';
      });
    }
  }

  Future<void> _updateMarkers() async {
    final Set<Marker> markers = {};

    // Add current user marker with custom design
    if (_currentPosition != null) {
      final currentUserMarker = await CustomMarkerGenerator.createCurrentUserMarker(
        initials: 'ME', // You can get this from user profile
      );
      
      markers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: _currentPosition!,
          icon: currentUserMarker,
          anchor: const Offset(0.5, 0.5),
          onTap: () => _onCurrentUserMarkerTap(),
        ),
      );
    }

    // Add friend markers with custom profile pictures
    for (final friend in _friends) {
      final position = LatLng(
        friend.latitude,
        friend.longitude,
      );

      final statusColor = CustomMarkerGenerator.getStatusColor(friend.availabilityStatus);
      final profileColor = CustomMarkerGenerator.getProfileColor(friend.fullName);
      
      final initials = friend.fullName.isNotEmpty 
          ? friend.fullName[0].toUpperCase()
          : friend.username[0].toUpperCase();

      final customMarker = await CustomMarkerGenerator.createProfileMarker(
        initials: initials,
        statusColor: statusColor,
        backgroundColor: profileColor,
      );

      markers.add(
        Marker(
          markerId: MarkerId('friend_${friend.userId}'),
          position: position,
          icon: customMarker,
          anchor: const Offset(0.5, 0.5),
          onTap: () => _onFriendMarkerTap(friend),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onCurrentUserMarkerTap() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateToPosition(
        _currentPosition!,
        zoom: 16.0,
      );
    }
  }

  void _onFriendMarkerTap(Friend friend) {
    // First, animate to the friend's location with zoom
    final friendPosition = LatLng(friend.latitude, friend.longitude);
    if (_mapController != null) {
      _mapController!.animateToPosition(
        friendPosition,
        zoom: 16.0,
      );
    }

    // Then show the enhanced popup
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FriendInfoPopup(friend: friend),
    );
  }


  void _showAllFriends() {
    if (_friends.isEmpty || _mapController == null) return;

    // Calculate bounds to show all friends
    double minLat = _friends.first.latitude;
    double maxLat = _friends.first.latitude;
    double minLng = _friends.first.longitude;
    double maxLng = _friends.first.longitude;

    for (final friend in _friends) {
      final lat = friend.latitude;
      final lng = friend.longitude;
      minLat = minLat < lat ? minLat : lat;
      maxLat = maxLat > lat ? maxLat : lat;
      minLng = minLng < lng ? minLng : lng;
      maxLng = maxLng > lng ? maxLng : lng;
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
          // Logout button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: "logout_button",
              backgroundColor: Colors.red.withOpacity(0.9),
              onPressed: () => _showLogoutDialog(),
              child: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
          
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?\n\nThis will stop location sharing and you\'ll need to login again.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
