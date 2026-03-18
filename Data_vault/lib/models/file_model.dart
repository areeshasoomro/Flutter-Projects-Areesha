import 'package:cloud_firestore/cloud_firestore.dart';

enum FileStatus { active, expired, limitReached, blocked }

class FileModel {
  final String id;
  final String ownerId;
  final String fileName;
  final String fileUrl;
  final DateTime createdAt;
  final DateTime expiryTime;
  final int maxViews;
  final int currentViews;
  final FileStatus status;
  final String? password;

  FileModel({
    required this.id,
    required this.ownerId,
    required this.fileName,
    required this.fileUrl,
    required this.createdAt,
    required this.expiryTime,
    required this.maxViews,
    required this.currentViews,
    required this.status,
    this.password,
  });

  factory FileModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    
    return FileModel(
      id: doc.id,
      ownerId: data['ownerId']?.toString() ?? '',
      fileName: data['fileName']?.toString() ?? 'Unnamed File',
      fileUrl: data['fileUrl']?.toString() ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      expiryTime: _parseTimestamp(data['expiryTime'], fallbackDays: 1),
      maxViews: (data['maxViews'] as num?)?.toInt() ?? 0,
      currentViews: (data['currentViews'] as num?)?.toInt() ?? 0,
      status: _parseStatus(data['status']?.toString()),
      password: data['password']?.toString(),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp, {int fallbackDays = 0}) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now().add(Duration(days: fallbackDays));
  }

  static FileStatus _parseStatus(String? status) {
    switch (status) {
      case 'active': return FileStatus.active;
      case 'expired': return FileStatus.expired;
      case 'limitReached': return FileStatus.limitReached;
      case 'blocked': return FileStatus.blocked;
      default: return FileStatus.active;
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiryTime);
  bool get isLimitReached => currentViews >= maxViews && maxViews != 0;
  bool get isAccessAllowed => !isExpired && !isLimitReached && status == FileStatus.active;
  bool get isPasswordProtected => password != null && password!.isNotEmpty;
}
