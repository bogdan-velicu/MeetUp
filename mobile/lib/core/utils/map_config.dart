import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/env_config.dart';

class MapConfig {
  static String get apiKey => EnvConfig.googleMapsApiKey;
  
  // Default camera position (can be changed based on user location)
  static const CameraPosition defaultCameraPosition = CameraPosition(
    target: LatLng(44.4268, 26.1025), // Bucharest, Romania
    zoom: 12.0,
  );
  
  // Map style (optional - can customize map appearance)
  static const String mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
  ''';
}

