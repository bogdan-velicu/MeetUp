import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _selectedAddress = widget.initialAddress;
    if (_selectedPosition == null) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
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
    if (_selectedPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 15.0),
      );
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
      body: Column(
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
                      }
                    },
                    onChanged: (value) {
                      // Search query changed, but we only search on submit
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

          // Selected address display
          if (_selectedAddress != null || _isLoadingAddress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoadingAddress
                        ? const Text(
                            'Loading address...',
                            style: TextStyle(fontSize: 14),
                          )
                        : Text(
                            _selectedAddress!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
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

                // Center indicator
                const Center(
                  child: Icon(
                    Icons.place,
                    color: Colors.red,
                    size: 40,
                  ),
                ),

                // Instructions
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap on the map or search to select a location',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

