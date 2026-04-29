import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/note.dart';
import '../providers/note_provider.dart';

class EditNoteScreen extends StatefulWidget {
  final Note? note;
  final int? index;

  const EditNoteScreen({super.key, this.note, this.index});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textBeforeListening = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _speech = stt.SpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) => setState(() => _isListening = false),
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _textBeforeListening = _contentController.text;
        });
        
        _speech.listen(
          onResult: (val) {
            setState(() {
              String newWords = val.recognizedWords;
              if (newWords.isNotEmpty) {
                String prefix = _textBeforeListening.isEmpty ? '' : '$_textBeforeListening ';
                _contentController.text = '$prefix$newWords';
                _contentController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _contentController.text.length),
                );
              }
            });
          },
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _saveNote() {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final note = Note(
      title: _titleController.text.isEmpty ? 'Untitled Note' : _titleController.text,
      content: _contentController.text,
      timestamp: DateTime.now(),
    );

    if (widget.index != null) {
      noteProvider.updateNote(widget.index!, note);
    } else {
      noteProvider.addNote(note);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<NoteProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: _saveNote,
        ),
        title: Text(
          widget.index == null ? 'New Note' : 'Edit Note',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _saveNote,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        'Last edited: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _contentController,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start your voice note here...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ],
              ),
            ),
          ),
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _animationController,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Listening...',
                        style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.only(bottom: 40, top: 20),
            child: Center(
              child: GestureDetector(
                onTap: _listen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.redAccent : Colors.deepPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.redAccent : Colors.deepPurple).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
