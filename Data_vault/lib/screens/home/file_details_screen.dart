import 'dart:async';
import 'package:data_vault/models/file_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class FileDetailsScreen extends StatefulWidget {
  final FileModel file;
  const FileDetailsScreen({super.key, required this.file});

  @override
  State<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends State<FileDetailsScreen> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = widget.file.expiryTime.difference(DateTime.now());
          if (_timeLeft.isNegative) {
            _timeLeft = Duration.zero;
            _timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return "Expired";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${hours}h : ${minutes}m : ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vault Analytics"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fileAccessLogs')
            .where('fileId', isEqualTo: widget.file.id)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final logs = docs.toList();
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Real-time Timer Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.timer_outlined, size: 32, color: primaryColor),
                      const SizedBox(height: 12),
                      Text(
                        _formatDuration(_timeLeft),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "TIME UNTIL EXPIRATION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Activity Overview Section
                Text("ACCESS OVERVIEW", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: _buildPieChart(logs, primaryColor),
                      ),
                      const SizedBox(height: 32),
                      _buildLegendItem("Success", Colors.green, logs.where((l) => l['status'] == 'success').length),
                      const SizedBox(height: 8),
                      _buildLegendItem("Blocked/Denied", Colors.redAccent, logs.where((l) => l['status'] != 'success').length),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Access Logs Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("RECENT ACCESS LOGS", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    if (logs.isNotEmpty)
                      Text("${logs.length} ATTEMPTS", style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (snapshot.connectionState == ConnectionState.waiting && logs.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else
                  _buildAccessLogsList(logs, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieChart(List<QueryDocumentSnapshot> logs, Color primaryColor) {
    if (logs.isEmpty) {
      return PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(color: Colors.grey[900], value: 1, title: "", radius: 10),
          ],
          centerSpaceRadius: 40,
        ),
      );
    }

    int success = logs.where((l) => l['status'] == 'success').length;
    int denied = logs.length - success;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: success.toDouble(),
            title: success > 0 ? "$success" : "",
            radius: 12,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.redAccent,
            value: denied.toDouble(),
            title: denied > 0 ? "$denied" : "",
            radius: 12,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildAccessLogsList(List<dynamic> logs, ThemeData theme) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 40, color: Colors.grey[800]),
            const SizedBox(height: 12),
            Text("No activity detected yet", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      );
    }

    // Sort logs locally: newest first
    final sortedLogs = List.from(logs);
    sortedLogs.sort((a, b) {
      Timestamp t1 = a['accessedAt'] ?? Timestamp.now();
      Timestamp t2 = b['accessedAt'] ?? Timestamp.now();
      return t2.compareTo(t1);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedLogs.length > 10 ? 10 : sortedLogs.length,
      itemBuilder: (context, index) {
        var log = sortedLogs[index];
        Timestamp? timestamp = log['accessedAt'];
        DateTime date = timestamp?.toDate() ?? DateTime.now();
        String status = log['status'] ?? 'unknown';
        bool isSuccess = status == 'success';

        return Container(
          key: ValueKey(log.id),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline_rounded : Icons.block_flipped,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuccess ? "Authorized Access" : "Access Denied ($status)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      DateFormat('MMM dd • hh:mm:ss a').format(date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
