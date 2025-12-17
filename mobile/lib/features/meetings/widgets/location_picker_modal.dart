import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';

class LocationPickerModal extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const LocationPickerModal({
    super.key,
    this.initialPosition,
    this.initialAddress,
  });

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isSearching = false;
  bool _isLoadingAddress = false;
  bool _showBottomInfo = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _hideInfoTimer;
  List<Placemark> _addressSuggestions = [];
  bool _showSuggestions = false;
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _selectedAddress = widget.initialAddress;
    if (_selectedPosition == null) {
      _getCurrentLocation();
    }
    // Hide bottom info after 5 seconds
    _hideInfoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showBottomInfo = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideInfoTimer?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
      });
      _updateAddressFromPosition(_selectedPosition!);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Default to a known location (e.g., Bucharest)
      setState(() {
        _selectedPosition = const LatLng(44.4268, 26.1025);
      });
    }
  }

  Future<void> _updateAddressFromPosition(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = _formatAddress(place);
        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = '${position.latitude}, ${position.longitude}';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _selectedAddress = '${position.latitude}, ${position.longitude}';
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _searchAddressSuggestions(String query) async {
    if (query.trim().length < 4) {
      setState(() {
        _showSuggestions = false;
        _addressSuggestions = [];
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    try {
      // Use geocoding to get address suggestions
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        // Get placemarks for each location to show full addresses
        final List<Placemark> placemarks = [];
        for (final location in locations.take(5)) { // Limit to 5 suggestions
          try {
            final marks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );
            if (marks.isNotEmpty) {
              placemarks.add(marks.first);
            }
          } catch (e) {
            debugPrint('Error getting placemark: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _addressSuggestions = placemarks;
            _isLoadingSuggestions = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _addressSuggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching address suggestions: $e');
      if (mounted) {
        setState(() {
          _addressSuggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.insert(0, place.subThoroughfare!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final position = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _selectedPosition = position;
          _isSearching = false;
        });

        // Move map to the found location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 15.0),
        );

        // Update address
        await _updateAddressFromPosition(position);
      } else {
        setState(() {
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching address: $e');
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _updateAddressFromPosition(position);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Apply custom map style
    _applyMapStyle(controller);
    if (_selectedPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 15.0),
      );
    }
  }

  void _applyMapStyle(GoogleMapController controller) async {
    // Custom map style - minimalist gray theme (same as main map)
    const String mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#eeeeee"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
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
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e5e5e5"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#dadada"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "transit.line",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e5e5e5"
          }
        ]
      },
      {
        "featureType": "transit.station",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#eeeeee"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#c9c9c9"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      }
    ]
    ''';
    
    try {
      await controller.setMapStyle(mapStyle);
    } catch (e) {
      debugPrint('Error applying map style: $e');
    }
  }

  void _confirmSelection() {
    if (_selectedPosition != null) {
      Navigator.pop(context, {
        'latitude': _selectedPosition!.latitude.toString(),
        'longitude': _selectedPosition!.longitude.toString(),
        'address': _selectedAddress ?? '${_selectedPosition!.latitude}, ${_selectedPosition!.longitude}',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPosition != null)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for an address...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _searchAddress(value);
                        setState(() {
                          _showSuggestions = false;
                        });
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                      // Debounce address suggestions
                      _debounceTimer?.cancel();
                      if (value.trim().length >= 4) {
                        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                          _searchAddressSuggestions(value);
                        });
                      } else {
                        setState(() {
                          _showSuggestions = false;
                          _addressSuggestions = [];
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Use current location',
                ),
              ],
            ),
          ),

          // Selected address display with monochrome theme (always visible)
          if (_selectedAddress != null || _isLoadingAddress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundColor,
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoadingAddress
                        ? Text(
                            'Loading address...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Text(
                            _selectedAddress!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                  ),
                ],
              ),
            ),

          // Address suggestions dropdown
          if (_showSuggestions)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoadingSuggestions
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _addressSuggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('No suggestions found'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _addressSuggestions.length,
                          itemBuilder: (context, index) {
                            final placemark = _addressSuggestions[index];
                            final address = _formatAddress(placemark);
                            return ListTile(
                              leading: Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                              title: Text(
                                address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              onTap: () async {
                                try {
                                  final location = await locationFromAddress(address);
                                  if (location.isNotEmpty) {
                                    final position = LatLng(location.first.latitude, location.first.longitude);
                                    setState(() {
                                      _selectedPosition = position;
                                      _selectedAddress = address;
                                      _showSuggestions = false;
                                      _searchController.text = address;
                                    });
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(position, 15.0),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error selecting suggestion: $e');
                                }
                              },
                            );
                          },
                        ),
            ),

              // Map
              Expanded(
                child: Stack(
                  children: [
                    if (_selectedPosition != null)
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedPosition!,
                          zoom: 15.0,
                        ),
                        onMapCreated: _onMapCreated,
                        onTap: _onMapTap,
                        markers: _selectedPosition != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: _selectedPosition!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                              }
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Bottom info panel - positioned at the bottom of the entire page
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                offset: _showBottomInfo ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showBottomInfo ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap on the map or search to select a location',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

