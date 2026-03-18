import 'package:data_vault/models/file_model.dart';
import 'package:data_vault/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SecureAccessScreen extends StatefulWidget {
  final String fileId;
  const SecureAccessScreen({super.key, required this.fileId});

  @override
  State<SecureAccessScreen> createState() => _SecureAccessScreenState();    
}

class _SecureAccessScreenState extends State<SecureAccessScreen> {
  late FirebaseService _firebaseService;
  Future<FileModel?>? _fileFuture;
  final _passwordController = TextEditingController();
  bool _isAccessGranted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _firebaseService = context.read<FirebaseService>();
    _fileFuture = _fetchFile();
  }

  Future<FileModel?> _fetchFile() async {
    final doc = await FirebaseFirestore.instance.collection('files').doc(widget.fileId).get();
    if (!doc.exists) {
      await _firebaseService.logAccess(widget.fileId, 'not_found');
      return null;
    }
    return FileModel.fromFirestore(doc);
  }

  void _processAccess(FileModel file) async {
    setState(() => _isLoading = true);
    
    if (file.isExpired) {
      await _firebaseService.logAccess(file.id, 'expired');
      _showError("This link has expired.");
      setState(() => _isLoading = false);
      return;
    }

    if (file.isLimitReached) {
      await _firebaseService.logAccess(file.id, 'limit_reached');
      _showError("View limit reached.");
      setState(() => _isLoading = false);
      return;
    }
    

    if (file.isPasswordProtected && _passwordController.text != file.password) {
      await _firebaseService.logAccess(file.id, 'wrong_password');
      _showError("Incorrect Password.");
      setState(() => _isLoading = false);
      return;
    }

    await _firebaseService.logAccess(file.id, 'success');
    await _firebaseService.incrementViewCount(file.id);
    
    setState(() {
      _isAccessGranted = true;
      _isLoading = false;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError("Could not open download link.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("DataVault Portal"), 
        automaticallyImplyLeading: false, 
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<FileModel?>(
        future: _fileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data == null) {
            return const _AccessCard(icon: Icons.error_outline_rounded, message: "Vault Item Not Found", color: Colors.orange, isBlocked: true);
          }

          final file = snapshot.data!;

          if (file.isExpired) return const _AccessCard(icon: Icons.timer_off_outlined, message: "Access Window Expired", color: Colors.redAccent, isBlocked: true);
          if (file.isLimitReached && !_isAccessGranted) return const _AccessCard(icon: Icons.block_flipped, message: "Download Limit Reached", color: Colors.redAccent, isBlocked: true);

          if (!_isAccessGranted) {
            return _buildGatekeeper(file, theme, primaryColor);
          }

          return _AccessCard(
            icon: Icons.verified_user_outlined,
            message: "Access Authorized",
            fileName: file.fileName,
            color: primaryColor,
            isBlocked: false,
            onDownload: () => _launchURL(file.fileUrl),
          );
        },
      ),
    );
  }

  Widget _buildGatekeeper(FileModel file, ThemeData theme, Color primaryColor) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(file.isPasswordProtected ? Icons.lock_outline_rounded : Icons.shield_outlined, size: 48, color: primaryColor),
            ),
            const SizedBox(height: 24),
            Text(file.fileName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text("SECURE ACCESS REQUIRED", style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 40),
            if (file.isPasswordProtected) ...[
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: "Vault Password",
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : () => _processAccess(file),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                : Text(file.isPasswordProtected ? "UNLOCK VAULT" : "AUTHORIZE ACCESS", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? fileName;
  final Color color;
  final bool isBlocked;
  final VoidCallback? onDownload;

  const _AccessCard({required this.icon, required this.message, this.fileName, required this.color, required this.isBlocked, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: const Color(0xFF121212), 
          borderRadius: BorderRadius.circular(28), 
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(height: 32),
            if (fileName != null) ...[
              Text(fileName!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
            ],
            Text(message.toUpperCase(), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            if (!isBlocked) ...[
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text("DOWNLOAD SOURCE FILE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, 
                  foregroundColor: Colors.black, 
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
