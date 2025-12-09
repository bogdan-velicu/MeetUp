import 'package:flutter/material.dart';
import '../../services/meetings/meetings_service.dart';
import '../../models/meeting.dart';
import 'package:provider/provider.dart';
import '../../services/auth/auth_provider.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final int meetingId;

  const MeetingDetailsScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  final MeetingsService _meetingsService = MeetingsService();
  Meeting? _meeting;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeeting();
  }

  Future<void> _loadMeeting() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final meeting = await _meetingsService.getMeetingById(widget.meetingId);
      setState(() {
        _meeting = meeting;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading meeting: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMeeting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: const Text('Are you sure you want to delete this meeting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _meeting != null) {
      try {
        await _meetingsService.deleteMeeting(_meeting!.id);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting meeting: $e')),
          );
        }
      }
    }
  }

  bool _isOrganizer() {
    if (_meeting == null) return false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    return currentUser != null && currentUser['id'] == _meeting!.organizerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: _isOrganizer()
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteMeeting,
                ),
              ]
            : null,
      ),
      body: _isLoading
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
                        onPressed: _loadMeeting,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _meeting == null
                  ? const Center(child: Text('Meeting not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _meeting!.title ?? 'Untitled Meeting',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_meeting!.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _meeting!.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(_meeting!.status),
                              ),
                            ),
                          ),
                          if (_meeting!.description != null && _meeting!.description!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              _meeting!.description!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildInfoRow(Icons.access_time, 'Date & Time', _formatDateTime(_meeting!.scheduledAt)),
                          if (_meeting!.address != null) ...[
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.location_on, 'Location', _meeting!.address!),
                          ],
                          const SizedBox(height: 24),
                          const Text(
                            'Participants',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._meeting!.participants.map((participant) => _buildParticipantCard(participant)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(MeetingParticipant participant) {
    final userName = participant.user?.fullName ?? 
                     participant.user?.username ?? 
                     'User ${participant.userId}';
    final userInitial = participant.user?.fullName?.isNotEmpty == true
        ? participant.user!.fullName![0].toUpperCase()
        : participant.user?.username[0].toUpperCase() ?? 
          participant.userId.toString();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            userInitial,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(userName),
        subtitle: participant.user != null 
            ? Text('@${participant.user!.username}')
            : null,
        trailing: _getStatusChip(participant.status),
      ),
    );
  }

  Widget _getStatusChip(String status) {
    final color = _getParticipantStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
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

  Color _getParticipantStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

