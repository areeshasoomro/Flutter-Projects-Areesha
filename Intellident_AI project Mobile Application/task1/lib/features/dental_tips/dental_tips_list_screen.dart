import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dental_tip_model.dart';
import 'dental_tip_detail_screen.dart';

class DentalTipsListScreen extends StatefulWidget {
  const DentalTipsListScreen({super.key});

  @override
  State<DentalTipsListScreen> createState() => _DentalTipsListScreenState();
}

class _DentalTipsListScreenState extends State<DentalTipsListScreen> {
  // Official Brand Logo Colors
  static const Color logoDeepBlue = Color(0xFF0077B6);
  static const Color logoLightBlue = Color(0xFF48CAE4);
  static const Color logoAccentBlue = Color(0xFF90E0EF);

  List<DentalTip>? _tips;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDentalTips();
  }

  Future<void> _loadDentalTips() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/dental_tips.json');
      final List decodedData = json.decode(jsonString);
      
      setState(() {
        _tips = decodedData.map((e) => DentalTip.fromJson(e)).toList();
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load dental tips. Please try again later.";
        _tips = [];
      });
      debugPrint("Error loading JSON: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F9), // Softer background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: logoDeepBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dental Tips',
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: logoDeepBlue, 
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _tips == null
          ? const Center(
              child: CircularProgressIndicator(color: logoDeepBlue),
            )
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: _tips!.length,
                  itemBuilder: (context, index) {
                    final tip = _tips![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DentalTipDetailScreen(tip: tip),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: logoDeepBlue.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: logoAccentBlue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.tips_and_updates_outlined, 
                                    color: logoDeepBlue, 
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tip.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF1B263B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tip.shortDescription,
                                        style: TextStyle(
                                          color: Colors.grey.shade600, 
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios, 
                                  size: 16, 
                                  color: logoDeepBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
