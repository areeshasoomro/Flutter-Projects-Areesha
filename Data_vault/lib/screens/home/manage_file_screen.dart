import 'package:data_vault/models/file_model.dart';
import 'package:data_vault/screens/home/file_details_screen.dart';
import 'package:data_vault/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ManageFileScreen extends StatelessWidget {
  final FileModel file;
  const ManageFileScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final firebase = context.read<FirebaseService>();
    final theme = Theme.of(context);
    bool isActive = file.isAccessAllowed;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Vault"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    file.fileName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? "ACTIVE SESSION" : "ACCESS EXPIRED",
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Section
            _buildSectionTitle("Access Statistics"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatBox("Views", "${file.currentViews}", theme)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox("Limit", file.maxViews == 0 ? "∞" : "${file.maxViews}", theme)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle("Configuration"),
            const SizedBox(height: 12),
            _buildDetailTile(Icons.event_available_rounded, "Expires On", DateFormat('MMM dd, hh:mm a').format(file.expiryTime), theme),
            _buildDetailTile(Icons.lock_outline_rounded, "Protection", file.isPasswordProtected ? "Password Active" : "No Password", theme),
            
            const SizedBox(height: 32),
            
            // Actions
            _buildActionButton(
              icon: Icons.copy_rounded,
              label: "Copy Secure Portal Link",
              onPressed: () {
                final String portalUrl = "https://datavault-76ca3.web.app/?id=${file.id}";
                Clipboard.setData(ClipboardData(text: portalUrl));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard")));
              },
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.analytics_outlined,
              label: "View Access Analytics",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FileDetailsScreen(file: file)));
              },
              theme: theme,
              isOutlined: true,
            ),
            
            const SizedBox(height: 48),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),
            
            // Danger Zone
            Text("DANGER ZONE", style: TextStyle(color: Colors.red[400], fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildDangerButton(
              icon: Icons.block_flipped,
              label: "Revoke All Access",
              subtitle: "Instantly expire this link",
              onPressed: !isActive ? null : () => _confirmRevoke(context, firebase),
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildDangerButton(
              icon: Icons.delete_forever_rounded,
              label: "Delete from Vault",
              subtitle: "Permanent deletion of data",
              onPressed: () => _confirmDelete(context, firebase),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildStatBox(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onPressed, required ThemeData theme, bool isOutlined = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : theme.colorScheme.primary,
        foregroundColor: isOutlined ? theme.colorScheme.primary : Colors.black,
        elevation: 0,
        side: isOutlined ? BorderSide(color: theme.colorScheme.primary) : null,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDangerButton({required IconData icon, required String label, required String subtitle, required VoidCallback? onPressed, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: color.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext context, FirebaseService firebase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Revoke Access?"),
        content: const Text("This link will stop working for everyone immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () {
            firebase.revokeAccess(file.id);
            Navigator.pop(context);
            Navigator.pop(context);
          }, child: const Text("Revoke", style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirebaseService firebase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Delete Vault Item?"),
        content: const Text("This action cannot be undone. All logs and data will be lost."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () {
            firebase.deleteFile(file.id);
            Navigator.pop(context);
            Navigator.pop(context);
          }, child: const Text("Delete Permanently", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
