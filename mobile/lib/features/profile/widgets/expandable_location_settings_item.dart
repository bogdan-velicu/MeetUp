import 'package:flutter/material.dart';
import '../../../services/location/location_update_service.dart';
import '../../../core/theme/app_theme.dart';

class ExpandableLocationSettingsItem extends StatefulWidget {
  const ExpandableLocationSettingsItem({super.key});

  @override
  State<ExpandableLocationSettingsItem> createState() => _ExpandableLocationSettingsItemState();
}

class _ExpandableLocationSettingsItemState extends State<ExpandableLocationSettingsItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  late int _updateInterval;
  late int _distanceFilter;
  late bool _backgroundUpdates;
  late bool _isUpdating;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main row (similar to Privacy)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Settings',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isUpdating ? 'Location updates active' : 'Location updates stopped',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expandable content
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Status indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isUpdating 
                        ? AppTheme.successColor.withOpacity(0.1) 
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isUpdating 
                          ? AppTheme.successColor.withOpacity(0.3)
                          : AppTheme.errorColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isUpdating ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        color: _isUpdating ? AppTheme.successColor : AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isUpdating ? 'Location updates active' : 'Location updates stopped',
                        style: TextStyle(
                          color: _isUpdating ? AppTheme.successColor : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Update interval
                Text(
                  'Update Interval',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _updateInterval.toDouble(),
                        min: 10,
                        max: 300,
                        divisions: 29,
                        label: '${_updateInterval}s',
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: Colors.grey[300],
                        onChanged: (value) {
                          setState(() {
                            _updateInterval = value.round();
                          });
                        },
                        onChangeEnd: (_) => _updateSettings(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_updateInterval}s',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Distance filter
                Text(
                  'Distance Filter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _distanceFilter.toDouble(),
                        min: 5,
                        max: 100,
                        divisions: 19,
                        label: '${_distanceFilter}m',
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: Colors.grey[300],
                        onChanged: (value) {
                          setState(() {
                            _distanceFilter = value.round();
                          });
                        },
                        onChangeEnd: (_) => _updateSettings(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_distanceFilter}m',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Background updates toggle
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      'Background Updates',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Continue updating location when app is in background',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    value: _backgroundUpdates,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _backgroundUpdates = value;
                      });
                      _updateSettings();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Control buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUpdating ? null : () async {
                          try {
                            await locationUpdateService.startLocationUpdates();
                            _loadSettings();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to start updates: $e'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: !_isUpdating ? null : () {
                          locationUpdateService.stopLocationUpdates();
                          _loadSettings();
                        },
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('Stop'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success = await locationUpdateService.updateLocationNow();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success ? 'Location updated successfully' : 'Failed to update location',
                            ),
                            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Update Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

