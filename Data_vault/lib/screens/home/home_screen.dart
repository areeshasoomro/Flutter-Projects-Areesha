import 'package:data_vault/models/file_model.dart';
import 'package:data_vault/screens/home/manage_file_screen.dart';
import 'package:data_vault/services/auth_service.dart';
import 'package:data_vault/services/firebase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

/**
 * HomeScreen
 * The primary dashboard for file owners.
 * Provides a real-time list of vault items, file management, and upload capabilities.
 */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firebase = context.read<FirebaseService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("DataVault", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            onPressed: () => auth.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<FileModel>>(
        // Real-time stream of files belonging to the current user
        stream: firebase.streamUserFiles(auth.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text("Connection Error", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 24),
                  Text("No files in vault", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Upload your first secure file to get started", style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                ],
              ),
            );
          }

          final files = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _FileCard(file: file);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadBottomSheet(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // Opens the modular bottom sheet for new file creation
  void _showUploadBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => const UploadBottomSheet(),
    );
  }
}

/**
 * _FileCard
 * A stylized card representing an individual vault item.
 * Displays real-time status and quick actions (Share, Manage, Delete).
 */
class _FileCard extends StatelessWidget {
  final FileModel file;
  const _FileCard({required this.file});

  // Displays a confirmation dialog before permanent deletion
  void _deleteFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Delete File?"),
        content: const Text("This will remove the record from your vault permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              context.read<FirebaseService>().deleteFile(file.id);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isActive = file.isAccessAllowed;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          // Navigate to management screen for detailed controls
          Navigator.push(context, MaterialPageRoute(builder: (context) => ManageFileScreen(file: file)));
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. File Header: Icon, Name, and Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.insert_drive_file_rounded, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _StatusChip(isActive: isActive),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                    onPressed: () => _deleteFile(context),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.white10, height: 1),
              ),
              // 2. Metrics: Views and Expiration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(
                      label: "ACCESS COUNT",
                      value: "${file.currentViews} / ${file.maxViews == 0 ? '∞' : file.maxViews}"),
                  _InfoItem(
                      label: "EXPIRATION",
                      value: DateFormat('MMM dd • hh:mm a').format(file.expiryTime)),
                ],
              ),
              const SizedBox(height: 24),
              // 3. Action Row
              Row(
                children: [
                  Expanded(
                    child: _buildCardButton(
                      icon: Icons.share_rounded,
                      label: "SHARE",
                      onPressed: () {
                        // Shares the Portal Link instead of the raw file URL for security
                        final portalUrl = "https://datavault-76ca3.web.app/?id=${file.id}";
                        Share.share('🔒 Secure File: ${file.fileName}\nAccess Link: $portalUrl');
                      },
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCardButton(
                      icon: Icons.settings_input_component_rounded,
                      label: "MANAGE",
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ManageFileScreen(file: file)));
                      },
                      theme: theme,
                      isPrimary: true,
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

  // Helper to build uniform action buttons inside the card
  Widget _buildCardButton({required IconData icon, required String label, required VoidCallback onPressed, required ThemeData theme, bool isPrimary = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? theme.colorScheme.primary : Colors.white.withOpacity(0.05),
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/**
 * _StatusChip
 * Visual indicator of the vault item's current availability state.
 */
class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    Color color = isActive ? const Color(0xFFA3E635) : Colors.redAccent;
    String label = isActive ? "ACTIVE" : "EXPIRED";
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ],
    );
  }
}

/**
 * _InfoItem
 * Helper widget for displaying key-value data points with high-contrast typography.
 */
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

/**
 * UploadBottomSheet
 * Interactive form for configuring security parameters and uploading assets.
 */
class UploadBottomSheet extends StatefulWidget {
  const UploadBottomSheet({super.key});

  @override
  State<UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<UploadBottomSheet> {
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  final _maxViewsController = TextEditingController(text: "5");
  DateTime _selectedExpiry = DateTime.now().add(const Duration(hours: 24));
  bool _isUploading = false;
  bool _obscurePassword = true;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _maxViewsController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Opens native file picker to select assets for secure sharing
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null) {
        setState(() {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Picking failed: $e")));
    }
  }

  // Opens native Date and Time pickers to establish precise expiration windows
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: Theme.of(context).colorScheme.primary)), child: child!),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedExpiry),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: Theme.of(context).colorScheme.primary)), child: child!),
    );
    if (time == null) return;

    setState(() {
      _selectedExpiry = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // Orchestrates the multi-stage upload process: 
  // 1. Cloudinary Hosting -> 2. Firestore Metadata Save
  Future<void> _upload() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;
    setState(() => _isUploading = true);
    
    try {
      final firebase = context.read<FirebaseService>();
      final auth = context.read<AuthService>();
      int maxViews = int.tryParse(_maxViewsController.text) ?? 0;

      String? fileId = await firebase.uploadFile(
        fileBytes: _selectedFileBytes!,
        ownerId: auth.uid,
        fileName: _selectedFileName!,
        expiryTime: _selectedExpiry,
        maxViews: maxViews,
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        if (fileId != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authorized & Secured!")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 32, right: 32, top: 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("NEW VAULT ITEM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 32),
            // File Selection Area
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05), style: BorderStyle.solid),
                ),
                child: _selectedFileName == null 
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary, size: 32), const SizedBox(height: 12), Text("SELECT SOURCE FILE", style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified_rounded, color: theme.colorScheme.primary), const SizedBox(width: 12), Flexible(child: Text(_selectedFileName!, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
              ),
            ),
            const SizedBox(height: 32),
            _buildInputHeader("SECURITY PARAMETERS"),
            const SizedBox(height: 16),
            // Max Views Input
            TextField(
              controller: _maxViewsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "MAXIMUM VIEWS (0 = UNLIMITED)", prefixIcon: Icon(Icons.remove_red_eye_rounded, size: 20)),
            ),
            const SizedBox(height: 16),
            // Optional Password Protection (Stretch Goal)
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "ENCRYPTION PASSWORD (OPTIONAL)", 
                prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildInputHeader("TIME ACCESS WINDOW"),
            const SizedBox(height: 16),
            // Expiration Window Selection Tile
            InkWell(
              onTap: _isUploading ? null : _selectDateTime,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("EXPIRES ON", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900)),
                        Text(DateFormat('MMM dd, yyyy • hh:mm a').format(_selectedExpiry), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.edit_rounded, color: Colors.grey[800], size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Main Execution Button
            ElevatedButton(
              onPressed: (_selectedFileBytes == null || _isUploading) ? null : _upload,
              child: _isUploading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                : const Text("GENERATE SECURE VAULT ITEM"),
            ),
          ],
        ),
      ),
    );
  }

  // Label helper for categorized input sections
  Widget _buildInputHeader(String title) {
    return Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }
}
