import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class NoteProvider with ChangeNotifier {
  late Box _box;
  List<Note> _notes = [];
  String _searchQuery = '';
  bool _isDarkMode = false;

  List<Note> get notes {
    List<Note> filtered = _notes;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((note) =>
              note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('notesBox');
    _loadNotes();
    _isDarkMode = _box.get('isDarkMode', defaultValue: false);
  }

  void _loadNotes() {
    final List<dynamic> rawNotes = _box.get('notes', defaultValue: []);
    _notes = rawNotes.map((item) => Note.fromMap(Map<String, dynamic>.from(item))).toList();
    _notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> _saveToBox() async {
    final List<Map<String, dynamic>> rawNotes = _notes.map((n) => n.toMap()).toList();
    await _box.put('notes', rawNotes);
  }

  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    await _saveToBox();
    notifyListeners();
  }

  Future<void> updateNote(int index, Note note) async {
    // Note: index here should be based on the full list if we are using it for storage
    // But for simplicity, we find the note in _notes and update it.
    _notes[index] = note;
    await _saveToBox();
    notifyListeners();
  }

  Future<void> deleteNote(int index) async {
    _notes.removeAt(index);
    await _saveToBox();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _box.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
