import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import '../../services/shake/shake_service.dart';
import '../../services/location/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class ShakeToMeetUpScreen extends StatefulWidget {
  const ShakeToMeetUpScreen({super.key});

  @override
  State<ShakeToMeetUpScreen> createState() => _ShakeToMeetUpScreenState();
}

class _ShakeToMeetUpScreenState extends State<ShakeToMeetUpScreen> {
  final ShakeService _shakeService = ShakeService();
  final LocationService _locationService = LocationService();
  ShakeDetector? _shakeDetector;
  
  bool _isShaking = false;
  bool _isProcessing = false;
  String _statusMessage = 'Shake your phone to find nearby friends!';
  List<Map<String, dynamic>> _nearbyFriends = [];
  Timer? _statusTimer;
  Timer? _pollTimer;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeShakeDetection();
    _getCurrentLocation();
    _startPollingNearbyFriends();
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    _statusTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _initializeShakeDetection() {
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) {
        _handleShake();
      },
      shakeThresholdGravity: 2.7,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      minimumShakeCount: 1,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _startPollingNearbyFriends() {
    // Poll every 2 seconds for nearby friends
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentPosition != null && !_isProcessing) {
        try {
          final friends = await _shakeService.getNearbyShakingFriends(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          if (mounted) {
            setState(() {
              _nearbyFriends = friends;
            });
          }
        } catch (e) {
          debugPrint('Error polling nearby friends: $e');
        }
      }
    });
  }

  Future<void> _handleShake() async {
    if (_isProcessing) return; // Prevent multiple simultaneous shakes

    setState(() {
      _isShaking = true;
      _isProcessing = true;
      _statusMessage = 'Processing shake...';
    });

    try {
      final result = await _shakeService.initiateShake();

      if (mounted) {
        if (result['matched'] == true) {
          // Match found!
          setState(() {
            _statusMessage = result['message'] ?? '🎉 Shake Match!';
            _isShaking = false;
          });

          // Show success dialog
          _showMatchSuccessDialog(result);

          // Stop polling
          _pollTimer?.cancel();
        } else {
          // No match yet, keep trying
          setState(() {
            _statusMessage = result['message'] ?? 'Keep shaking! Looking for nearby friends...';
            _isShaking = false;
          });

          // Reset status message after 3 seconds
          _statusTimer?.cancel();
          _statusTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _statusMessage = 'Shake your phone to find nearby friends!';
              });
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
          _isShaking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showMatchSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Shake Match!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You matched with ${result['matched_user_name'] ?? 'a friend'}!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'You earned ${result['points_awarded'] ?? 50} points!',
              style: TextStyle(
                color: Colors.amber[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shake to MeetUp'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isShaking)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      )
                    else
                      Icon(
                        Icons.phone_android,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_nearbyFriends.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_nearbyFriends.length} friend${_nearbyFriends.length != 1 ? 's' : ''} shaking nearby!',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Nearby friends list
              if (_nearbyFriends.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Nearby Friends Shaking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _nearbyFriends.length,
                            itemBuilder: (context, index) {
                              final friend = _nearbyFriends[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    (friend['full_name'] ?? friend['username'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(friend['full_name'] ?? friend['username'] ?? 'Unknown'),
                                subtitle: Text('${friend['distance_m']}m away'),
                                trailing: Icon(
                                  Icons.phone_android,
                                  color: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No nearby friends shaking',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Shake your phone to start!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Shake your phone when you\'re near a friend. Both of you need to shake within 15 seconds!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

