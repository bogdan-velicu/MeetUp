import 'package:flutter/material.dart';
import '../../../services/location/location_update_service.dart';

class LocationSettingsWidget extends StatefulWidget {
  const LocationSettingsWidget({super.key});

  @override
  State<LocationSettingsWidget> createState() => _LocationSettingsWidgetState();
}

class _LocationSettingsWidgetState extends State<LocationSettingsWidget> {
  late int _updateInterval;
  late int _distanceFilter;
  late bool _backgroundUpdates;
  late bool _isUpdating;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _updateInterval = locationUpdateService.updateIntervalSeconds;
      _distanceFilter = locationUpdateService.distanceFilterMeters;
      _backgroundUpdates = locationUpdateService.backgroundUpdatesEnabled;
      _isUpdating = locationUpdateService.isUpdating;
    });
  }

  void _updateSettings() {
    locationUpdateService.updateSettings(
      intervalSeconds: _updateInterval,
      distanceFilter: _distanceFilter,
      backgroundEnabled: _backgroundUpdates,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location settings updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Location Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Location updates status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isUpdating ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isUpdating ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUpdating ? Icons.check_circle : Icons.error,
                    color: _isUpdating ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isUpdating ? 'Location updates active' : 'Location updates stopped',
                    style: TextStyle(
                      color: _isUpdating ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Update interval slider
            Text(
              'Update Interval: ${_updateInterval}s',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _updateInterval.toDouble(),
              min: 10,
              max: 300,
              divisions: 29,
              label: '${_updateInterval}s',
              onChanged: (value) {
                setState(() {
                  _updateInterval = value.round();
                });
              },
              onChangeEnd: (_) => _updateSettings(),
            ),
            const SizedBox(height: 16),
            
            // Distance filter slider
            Text(
              'Distance Filter: ${_distanceFilter}m',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _distanceFilter.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              label: '${_distanceFilter}m',
              onChanged: (value) {
                setState(() {
                  _distanceFilter = value.round();
                });
              },
              onChangeEnd: (_) => _updateSettings(),
            ),
            const SizedBox(height: 16),
            
            // Background updates toggle
            SwitchListTile(
              title: const Text('Background Updates'),
              subtitle: const Text('Continue updating location when app is in background'),
              value: _backgroundUpdates,
              onChanged: (value) {
                setState(() {
                  _backgroundUpdates = value;
                });
                _updateSettings();
              },
            ),
            const SizedBox(height: 16),
            
            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : () async {
                      try {
                        await locationUpdateService.startLocationUpdates();
                        _loadSettings();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to start updates: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_isUpdating ? null : () {
                      locationUpdateService.stopLocationUpdates();
                      _loadSettings();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await locationUpdateService.updateLocationNow();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Location updated successfully' : 'Failed to update location',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Update Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
