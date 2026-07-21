import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OutfitDetailsPage extends StatefulWidget {
  final String userId;
  final StyledOutfit outfit;

  const OutfitDetailsPage({
    required this.userId,
    required this.outfit,
    super.key,
  });

  @override
  State<OutfitDetailsPage> createState() => _OutfitDetailsPageState();
}

class _OutfitDetailsPageState extends State<OutfitDetailsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.outfit.name);
    _notesController = TextEditingController(text: widget.outfit.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final outfitId = widget.outfit.outfitId;
    if (outfitId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users/${widget.userId}/styledOutfits')
          .doc(outfitId)
          .update({
        'name': _nameController.text.trim().isEmpty
            ? 'Untitled look'
            : _nameController.text.trim(),
        'notes': _notesController.text.trim(),
        'updatedAt': Timestamp.now(),
      });
      if (!mounted) {
        return;
      }
      AlertService().showToast(
        text: 'Outfit details updated.',
        icon: Icons.check_circle_outline,
      );
      Navigator.of(context).pop();
    } catch (_) {
      AlertService().showToast(
        text: 'Could not update this outfit.',
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FB),
      appBar: AppBar(
        title: const Text('Outfit details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Label this look',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Give the outfit a name and add notes you will actually use later, like event, season, fit notes, or why it works.',
                  style: TextStyle(
                    color: Color(0xFF6C647A),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Outfit name',
                    hintText: 'Weekend brunch layers',
                    filled: true,
                    fillColor: const Color(0xFFF8F6FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText:
                        'Examples: good for mild weather, travel-friendly, works with white sneakers, date night backup.',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F6FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D56A8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(_saving ? 'Saving...' : 'Save details'),
            ),
          ),
        ],
      ),
    );
  }
}
