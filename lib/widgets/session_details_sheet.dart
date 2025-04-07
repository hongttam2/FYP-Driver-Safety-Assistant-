import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/driving_session.dart';

class SessionDetailsSheet extends StatelessWidget {
  final DrivingSession session;

  const SessionDetailsSheet({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y - h:mm a');
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Session Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),                                           //detail to be dispaly in details sheet
          _buildDetailRow('Start Time', dateFormat.format(session.startTime)),
          _buildDetailRow('End Time', dateFormat.format(session.endTime)),
          _buildDetailRow('Total Blinks', session.totalBlinks.toString()),
          _buildDetailRow('Phone Checks', session.phoneChecks.toString()),
          _buildDetailRow(
            'Long Blinks',
            session.longBlinks.toString(),
          ),
          _buildDetailRow('Average Blink Per minute ', _calculateAvgBlinksPerMinute().toStringAsFixed(1)),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
    }
double _calculateAvgBlinksPerMinute() {
  final durationInMinutes = session.endTime.difference(session.startTime).inMinutes;
  if (durationInMinutes == 0) {
    return session.totalBlinks.toDouble();
  }
  return session.totalBlinks / durationInMinutes;
}
  }

  
