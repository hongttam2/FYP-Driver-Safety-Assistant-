import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/driving_session.dart';
import '../services/storage_service.dart';
import 'session_details_sheet.dart';
import 'session_blink_chart.dart';

class SessionCard extends StatefulWidget {
  final DrivingSession session;
  final VoidCallback? onSessionUpdated;

  const SessionCard({
    super.key,
    required this.session,
    this.onSessionUpdated,
  });

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  final StorageService _storageService = StorageService();
  String? _sessionName;

  @override
  void initState() {
    super.initState();
    _sessionName = widget.session.name ?? _getDefaultSessionName();
  }

  String _getDefaultSessionName() {
    return DateFormat('MMM d, y - h:mm a').format(widget.session.startTime);
  }

  Future<void> _showRenameDialog() async {
    final TextEditingController controller = TextEditingController(text: _sessionName);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session Name',
            hintText: 'Enter a new name for this session',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('RENAME'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await _storageService.updateSessionName(widget.session.id, result.trim());
        setState(() {
          _sessionName = result.trim();
        });
        if (widget.onSessionUpdated != null) {
          widget.onSessionUpdated!();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to rename session')),
          );
        }
      }
    }
  }

  void _showSessionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SessionDetailsSheet(session: widget.session),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _calculateAvgBlinksPerMinute() {
    final duration = widget.session.endTime.difference(widget.session.startTime);
    final minutes = duration.inMinutes > 0 ? duration.inMinutes : 1; // Avoid division by zero
    final avgBlinksPerMinute = widget.session.totalBlinks / minutes;
    return avgBlinksPerMinute.toStringAsFixed(1); // Show one decimal place for better display
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.session.endTime.difference(widget.session.startTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showSessionDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
  children: [
    const Icon(Icons.drive_eta, size: 24),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        _sessionName ?? _getDefaultSessionName(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.edit, size: 20),
      onPressed: _showRenameDialog,
      tooltip: 'Rename session',
    ),
    IconButton(
      icon: const Icon(Icons.delete_outline, size: 20),
      onPressed: () => _showDeleteDialog(context),
      tooltip: 'Delete session',
    ),
    Text(
      _formatDuration(duration),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
    ),
  ],
),
              const Divider(height: 24),

              // Chart Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Blinks Per Minute',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SessionBlinkChart(session: widget.session),
                ],
              ),
              const Divider(height: 24),

         
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    'Phone Checks',
                    widget.session.phoneChecks.toString(),
                    Icons.phone_android,
                  ),
                  _buildStat(
                    'Avg Blink / Min', // Moved to middle
                    _calculateAvgBlinksPerMinute(),
                    Icons.timer,
                  ),
                  _buildStat(
                    'Long Blinks', // Replaced Total Blinks, moved to right
                    widget.session.longBlinks.toString(), // Assuming longBlinks exists
                    Icons.remove_red_eye,
                  ),
                ],
              ),

              // Info text
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap for detailed statistics',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Delete session comfimation log 

  Future<void> _showDeleteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Session'),
      content: const Text(
        'Are you sure you want to delete this session? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'DELETE',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (result == true) {
    try {
      await _storageService.deleteSession(widget.session.id);
      if (widget.onSessionUpdated != null) {
        widget.onSessionUpdated!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete session')),
        );
      }
    }
  }
}



  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}