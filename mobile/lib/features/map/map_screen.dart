import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/map_view_widget.dart';
import 'widgets/friend_info_popup.dart';
import 'widgets/custom_marker_generator.dart';
import '../../services/location/location_service.dart';
import '../../services/friends/friends_service.dart';
import '../../models/friend.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final FriendsService _friendsService = FriendsService();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  List<Friend> _friends = [];
  bool _isLoading = true;
  String? _error;
  MapViewController? _mapController;
  
  // Event-based completers
  Completer<void>? _mapControllerReadyCompleter;
  Completer<void>? _friendsLoadedCompleter;
  bool _friendsLoading = false;

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
    if (_friendsLoading) return; // Already loading
    
    _friendsLoading = true;
    try {
      final friends = await _friendsService.getFriendsLocations();
      setState(() {
        _friends = friends;
        _friendsLoading = false;
      });
      await _updateMarkers();
      
      // Notify that friends are loaded (event-based)
      _friendsLoadedCompleter?.complete();
      _friendsLoadedCompleter = null;
    } catch (e) {
      debugPrint('Error loading friends locations: $e');
      setState(() {
        _error = 'Error getting friends locations: $e';
        _friendsLoading = false;
      });
      // Complete with error
      _friendsLoadedCompleter?.completeError(e);
      _friendsLoadedCompleter = null;
    }
  }
  
  Future<void> _waitForFriendsLoaded({Duration timeout = const Duration(seconds: 5)}) async {
    if (_friends.isNotEmpty) {
      return; // Already loaded
    }
    
    if (_friendsLoadedCompleter == null) {
      _friendsLoadedCompleter = Completer<void>();
      if (!_friendsLoading) {
        _loadFriendsLocations();
      }
    }
    
    return _friendsLoadedCompleter!.future.timeout(
      timeout,
      onTimeout: () {
        debugPrint('Timeout waiting for friends to load');
        throw TimeoutException('Friends loading timeout');
      },
    );
  }
  
  Future<void> _waitForMapController({Duration timeout = const Duration(seconds: 5)}) async {
    if (_mapController != null) {
      return; // Already ready
    }
    
    // Create completer if it doesn't exist
    if (_mapControllerReadyCompleter == null) {
      _mapControllerReadyCompleter = Completer<void>();
    }
    
    // Double-check in case controller was set between the check and completer creation
    if (_mapController != null) {
      _mapControllerReadyCompleter?.complete();
      _mapControllerReadyCompleter = null;
      return;
    }
    
    return _mapControllerReadyCompleter!.future.timeout(
      timeout,
      onTimeout: () {
        debugPrint('Timeout waiting for map controller');
        throw TimeoutException('Map controller timeout');
      },
    );
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

  Future<void> focusOnFriend(int friendId) async {
    debugPrint('=== focusOnFriend START (event-based) ===');
    debugPrint('focusOnFriend called for friendId: $friendId');
    
    try {
      // Wait for events (with timeouts as fallback)
      debugPrint('Waiting for friends to load...');
      await _waitForFriendsLoaded(timeout: const Duration(seconds: 3));
      debugPrint('Friends loaded, count: ${_friends.length}');
      
      debugPrint('Waiting for map controller...');
      await _waitForMapController(timeout: const Duration(seconds: 3));
      debugPrint('Map controller ready');
      
      // Find the friend
      final friend = _friends.firstWhere(
        (f) => f.userId == friendId,
      );
      
      debugPrint('Found friend: ${friend.fullName} at ${friend.latitude}, ${friend.longitude}');
      
      final friendPosition = LatLng(friend.latitude, friend.longitude);
      
      // Animate to friend position
      debugPrint('Animating to friend position: $friendPosition');
      await _mapController!.animateToPosition(
        friendPosition,
        zoom: 16.0,
      );
      
      // Show the friend info popup after animation completes
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FriendInfoPopup(friend: friend),
        );
      }
      
      debugPrint('Successfully focused on friend');
    } on TimeoutException catch (e) {
      debugPrint('Timeout waiting for event: $e');
      // Fallback: try anyway if we have partial data
      if (_friends.isNotEmpty && _mapController != null) {
        try {
          final friend = _friends.firstWhere((f) => f.userId == friendId);
          await _mapController!.animateToPosition(
            LatLng(friend.latitude, friend.longitude),
            zoom: 16.0,
          );
        } catch (e) {
          debugPrint('Fallback also failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Error focusing on friend: $e');
      debugPrint('Available friend IDs: ${_friends.map((f) => f.userId).toList()}');
      rethrow;
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
                          // Notify that map controller is ready (event-based)
                          _mapControllerReadyCompleter?.complete();
                          _mapControllerReadyCompleter = null;
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
