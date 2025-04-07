import 'package:flutter/material.dart';
import '../providers/eye_tracking_provider.dart';

class SafetyStatsWidget extends StatelessWidget {
  final EyeTrackingProvider provider;

  const SafetyStatsWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {                      //display main stat in homescreen
    final stats = provider.getDebugStats(); 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            context: context,
            icon: Icons.remove_red_eye,
            label: 'Blink Rate',
            value: '${provider.blinksPerMinute.toStringAsFixed(1)}/min',
            isWarning: provider.blinksPerMinute < 10,
          ),
          const Divider(height: 24),
          _buildStatRow(
            context: context,
            icon: Icons.warning_amber_rounded, 
            label: 'Long Blinks',
            value: stats['longBlinkCount']?.toString() ?? '0', // Using existing stats
            isWarning: int.parse(stats['longBlinkCount']?.toString() ?? '0') > 5,
          ),
          const Divider(height: 24),
          _buildStatRow(
            context: context,
            icon: Icons.phone_android,
            label: 'Phone Checks',
            value: provider.phoneCheckCount.toString(),
            isWarning: provider.phoneCheckCount > 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required bool isWarning,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isWarning ? Colors.red : Colors.green,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: isWarning ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }
}