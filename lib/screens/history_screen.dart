import 'package:flutter/material.dart';
import '../models/driving_session.dart';
import '../services/storage_service.dart';
import '../widgets/session_card.dart';
import 'package:flutter/services.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<DrivingSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _storageService.getSessions();
      setState(() {
        _sessions = sessions..sort((a, b) => b.startTime.compareTo(a.startTime));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load sessions')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Driving History'),
  actions: [
    IconButton(
      icon: const Icon(Icons.content_copy),
      tooltip: 'Export Sessions Report',
      onPressed: _sessions.isEmpty
          ? null
          : () => _exportSessionsReport(context),
    ),
    IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: _sessions.isEmpty
          ? null
          : () => _showClearHistoryDialog(context),
    ),
  ],
),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No driving sessions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadSessions,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
  return RefreshIndicator(
    onRefresh: _loadSessions,
    child: ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        return SessionCard(
          session: _sessions[index],
          onSessionUpdated: _loadSessions,
        );
      },
    ),
  );
}

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all driving session records? This action cannot be undone.',      //dialog for comfirmation
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'CLEAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _storageService.clearSessions();
      await _loadSessions();
    }
  }


  void _exportSessionsReport(BuildContext context) {                     //export all session data 
  final report = _storageService.generateSessionsReport(_sessions);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sessions Report'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {                                             //button for copying to clipboard
            await Clipboard.setData(ClipboardData(text: report));
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report copied to clipboard')),       
              );
            }
          },
          child: const Text('COPY TO CLIPBOARD'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
      ],
    ),
  );
}


}