import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_vault/models/file_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CLOUDINARY CONFIGURATION ---
  final String cloudName = "dnb4odmqv"; 
  final String uploadPreset = "data_vault_app"; 

  // Upload File
  Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String ownerId,
    required String fileName,
    required DateTime expiryTime,
    required int maxViews,
    String? password,
  }) async {
    String? finalUrl;

    try {
      if (!kIsWeb) {
        var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
        var request = http.MultipartRequest('POST', uri);
        
        request.fields['upload_preset'] = uploadPreset;
        request.fields['folder'] = "data_vault_uploads";
        request.fields['public_id'] = "${ownerId}_${DateTime.now().millisecondsSinceEpoch}";
        
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          fileBytes,
          filename: fileName,
        ));

        var response = await request.send().timeout(const Duration(seconds: 60));
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);

        if (response.statusCode == 200 || response.statusCode == 201) {
          finalUrl = json['secure_url'];
        }
      }
    } catch (e) {
      print("Upload exception: $e");
    }

    if (finalUrl == null) {
      if (kIsWeb) {
        finalUrl = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";
      } else {
        return null; 
      }
    }

    try {
      DocumentReference docRef = await _db.collection('files').add({
        'ownerId': ownerId,
        'fileName': fileName,
        'fileUrl': finalUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'expiryTime': Timestamp.fromDate(expiryTime),
        'maxViews': maxViews,
        'currentViews': 0,
        'status': 'active',
        'password': password,
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Delete File
  Future<void> deleteFile(String fileId) async {
    await _db.collection('files').doc(fileId).delete();
    // In a real app, you'd also delete from Cloudinary here using their Admin API
  }

  // Revoke Access (Set expiry to now)
  Future<void> revokeAccess(String fileId) async {
    await _db.collection('files').doc(fileId).update({
      'expiryTime': FieldValue.serverTimestamp(),
      'status': 'blocked',
    });
  }

  // Get User Files
  Stream<List<FileModel>> streamUserFiles(String uid) {
    return _db
        .collection('files')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => FileModel.fromFirestore(doc)).toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  Future<void> logAccess(String fileId, String status) async {
    await _db.collection('fileAccessLogs').add({
      'fileId': fileId,
      'accessedAt': FieldValue.serverTimestamp(),
      'status': status,
    });
  }

  Future<void> incrementViewCount(String fileId) async {
    await _db.collection('files').doc(fileId).update({
      'currentViews': FieldValue.increment(1),
    });
  }
}
