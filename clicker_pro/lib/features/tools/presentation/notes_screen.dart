// lib/features/tools/presentation/notes_screen.dart
//
// A lightweight local scratchpad. Notes are persisted with shared_preferences
// (already a dependency) so they survive restarts and work fully offline —
// no backend, no Drift table needed for a personal note list.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _prefsKey = 'studio_notes';

  List<String> _notes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    setState(() {
      _notes = raw == null
          ? const []
          : (jsonDecode(raw) as List).cast<String>();
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_notes));
  }

  Future<void> _addOrEdit({int? index}) async {
    final controller =
        TextEditingController(text: index == null ? '' : _notes[index]);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          index == null ? 'New note' : 'Edit note',
          style: TextStyle(color: AppColors.film, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          style: TextStyle(color: AppColors.film),
          decoration: InputDecoration(
            hintText: 'Write a note…',
            hintStyle: TextStyle(color: AppColors.filmDim),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.line(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.filmDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    setState(() {
      if (index == null) {
        _notes = [text, ..._notes];
      } else {
        final copy = [..._notes];
        copy[index] = text;
        _notes = copy;
      }
    });
    await _persist();
  }

  Future<void> _delete(int index) async {
    setState(() {
      final copy = [..._notes]..removeAt(index);
      _notes = copy;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notes',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(
                  child: Text(
                    'No notes yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.filmDim),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _notes.length,
                  itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line(0.1)),
                    ),
                    child: ListTile(
                      title: Text(
                        _notes[i],
                        style: TextStyle(color: AppColors.film, fontSize: 14),
                      ),
                      onTap: () => _addOrEdit(index: i),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: AppColors.filmDim, size: 20),
                        onPressed: () => _delete(i),
                      ),
                    ),
                  ),
                ),
    );
  }
}
