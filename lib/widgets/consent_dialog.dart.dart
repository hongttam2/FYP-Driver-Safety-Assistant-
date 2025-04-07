import 'package:flutter/material.dart';

class ConsentDialog extends StatelessWidget {
  final VoidCallback onAccept;

  const ConsentDialog({
    Key? key,
    required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Important Note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'We want to assure you that any facial data captured by this application is processed in real-time and will never stored to your device\'s camera roll. The front camera is used solely for monitoring driver alertness and safety features within the app. Agree by clicking OK to continue using the app.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: onAccept,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}