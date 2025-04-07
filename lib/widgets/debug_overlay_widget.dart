import 'package:flutter/material.dart';
import '../providers/eye_tracking_provider.dart';

class DebugOverlayWidget extends StatelessWidget {
  final EyeTrackingProvider provider;

  const DebugOverlayWidget({                                    //display debug overlay in homescreen
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = provider.getDebugStats();
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...stats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}