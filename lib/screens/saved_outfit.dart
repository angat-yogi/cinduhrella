import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/styled_outfit_preview.dart';
import 'package:cinduhrella/screens/mix_match_studio_page.dart';
import 'package:cinduhrella/screens/outfit_details_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedOutfitsPage extends StatefulWidget {
  final String userId;

  const SavedOutfitsPage({required this.userId, super.key});

  @override
  SavedOutfitsPageState createState() => SavedOutfitsPageState();
}

class SavedOutfitsPageState extends State<SavedOutfitsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DatabaseService databaseService = DatabaseService();
  List<StyledOutfit> savedOutfits = [];

  @override
  void initState() {
    super.initState();
    fetchSavedOutfits();
  }

  Future<void> fetchSavedOutfits() async {
    List<StyledOutfit> outfits =
        await databaseService.fetchStyledOutfits(widget.userId);
    setState(() {
      savedOutfits = outfits;
    });
  }

  Future<void> updateOutfitLikeStatus(String outfitId, bool liked) async {
    try {
      await databaseService.updateOutfitLikeStatus(
          widget.userId, outfitId, liked);

      setState(() {
        for (var outfit in savedOutfits) {
          if (outfit.outfitId == outfitId) {
            outfit.liked = liked;
          }
        }
      });
    } catch (e) {
      debugPrint("Error updating like status: $e");
    }
  }

  Future<void> deleteOutfit(String outfitId) async {
    bool confirmDelete = await _showDeleteConfirmation();
    if (!confirmDelete) return;

    try {
      await firestore
          .collection('users/${widget.userId}/styledOutfits')
          .doc(outfitId)
          .delete();

      setState(() {
        savedOutfits.removeWhere((outfit) => outfit.outfitId == outfitId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit deleted successfully!")),
      );
    } catch (e) {
      debugPrint("Error deleting outfit: $e");
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Outfit"),
            content: const Text("Are you sure you want to delete this outfit?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showOutfitActions(StyledOutfit outfit) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFECE7FA),
                    foregroundColor: Color(0xFF6D56A8),
                    child: Icon(Icons.edit_note_rounded),
                  ),
                  title: const Text('Edit details'),
                  subtitle: const Text('Rename the outfit and add notes.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => OutfitDetailsPage(
                          userId: widget.userId,
                          outfit: outfit,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE7EEFF),
                    foregroundColor: Color(0xFF4D6CFA),
                    child: Icon(Icons.layers_outlined),
                  ),
                  title: const Text('Edit style'),
                  subtitle:
                      const Text('Open this saved board back inside Studio.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => MixMatchStudioPage(
                          userId: widget.userId,
                          initialOutfit: outfit,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFCE8E8),
                    foregroundColor: Colors.redAccent,
                    child: Icon(Icons.delete_outline_rounded),
                  ),
                  title: const Text('Delete outfit'),
                  onTap: () {
                    Navigator.of(context).pop();
                    deleteOutfit(outfit.outfitId!);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users/${widget.userId}/styledOutfits')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No saved outfits yet!"));
          }

          List<StyledOutfit> outfits = snapshot.data!.docs.map((doc) {
            return StyledOutfit.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              StyledOutfit outfit = outfits[index];

              return GestureDetector(
                onLongPress: () => _showOutfitActions(outfit),
                child: Card(
                  elevation: 1.5,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(outfit.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_note_rounded,
                                    color: Color(0xFF6D56A8),
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OutfitDetailsPage(
                                        userId: widget.userId,
                                        outfit: outfit,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      deleteOutfit(outfit.outfitId!),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 320,
                          child: StyledOutfitPreview(
                            outfit: outfit,
                            showTitle: false,
                          ),
                        ),
                        if (outfit.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              outfit.notes,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6C647A),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: Icon(Icons.thumb_up,
                                  color: outfit.liked
                                      ? Colors.green
                                      : Colors.grey),
                              onPressed: () => updateOutfitLikeStatus(
                                  outfit.outfitId!, true),
                            ),
                            IconButton(
                              icon: Icon(Icons.thumb_down,
                                  color: outfit.liked == false
                                      ? Colors.redAccent
                                      : Colors.grey),
                              onPressed: () => updateOutfitLikeStatus(
                                  outfit.outfitId!, false),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
