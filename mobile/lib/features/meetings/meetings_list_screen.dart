import 'package:flutter/material.dart';
import '../../services/meetings/meetings_service.dart';
import '../../models/meeting.dart';
import 'meeting_details_screen.dart';
import 'create_meeting_screen.dart';

class MeetingsListScreen extends StatefulWidget {
  const MeetingsListScreen({super.key});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> {
  final MeetingsService _meetingsService = MeetingsService();
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, organized, invited, upcoming, past
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMeetings();
      }
    });
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final meetings = await _meetingsService.getMeetings(filterType: _filterType);
      setState(() {
        _meetings = meetings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading meetings: $e';
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _filterType = filter;
    });
    _loadMeetings();
  }

  void _onMeetingTap(Meeting meeting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailsScreen(meetingId: meeting.id),
      ),
    ).then((_) => _loadMeetings()); // Refresh after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter chips with soft shadows and SafeArea for status bar
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('upcoming', 'Upcoming'),
                    const SizedBox(width: 8),
                    _buildFilterChip('past', 'Past'),
                    const SizedBox(width: 8),
                    _buildFilterChip('organized', 'Organized'),
                    const SizedBox(width: 8),
                    _buildFilterChip('invited', 'Invited'),
                  ],
                ),
              ),
            ),
          ),
          // Meetings list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMeetings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _meetings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No meetings found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create a new meeting to get started',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMeetings,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Extra bottom padding for FAB and nav
                              itemCount: _meetings.length,
                              itemBuilder: (context, index) {
                                final meeting = _meetings[index];
                                return _buildMeetingCard(meeting);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateMeetingScreen(),
            ),
          ).then((_) => _loadMeetings());
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
      floatingActionButtonLocation: _CustomFloatingActionButtonLocation(),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _filterType == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(filter),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.3)
            : Colors.grey.withOpacity(0.2),
        width: 1,
      ),
      elevation: isSelected ? 2 : 0,
      shadowColor: Colors.black.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    final statusColor = _getStatusColor(meeting.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
        onTap: () => _onMeetingTap(meeting),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meeting.title ?? 'Untitled Meeting',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      meeting.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (meeting.description != null && meeting.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  meeting.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(meeting.scheduledAt),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.address ?? 'Location TBD',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${meeting.participantCount} participant${meeting.participantCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (meetingDate == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (meetingDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${_formatTime(dateTime)}';
    } else if (meetingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}

// Custom FAB location that positions above the bottom navigation bar
class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Position at the end (right side)
    final double endX = scaffoldGeometry.scaffoldSize.width - 
        scaffoldGeometry.floatingActionButtonSize.width - 
        16.0; // 16px from right edge
    
    // Position above the bottom nav bar (accounting for nav bar height ~80px + safe area)
    final double bottomY = scaffoldGeometry.scaffoldSize.height - 
        scaffoldGeometry.floatingActionButtonSize.height - 
        100.0; // 100px from bottom to clear the nav bar
    
    return Offset(endX, bottomY);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.custom';
}

