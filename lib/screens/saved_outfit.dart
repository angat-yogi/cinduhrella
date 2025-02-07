import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SavedOutfitsPage extends StatefulWidget {
  final String userId;

  const SavedOutfitsPage({required this.userId, super.key});

  @override
  _SavedOutfitsPageState createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
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
      await firestore
          .collection('users/${widget.userId}/styledOutfits')
          .doc(outfitId)
          .update({'liked': liked});

      setState(() {
        for (var outfit in savedOutfits) {
          if (outfit.outfitId == outfitId) {
            outfit.liked = liked;
          }
        }
      });
    } catch (e) {
      print("Error updating like status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Saved Outfits"), backgroundColor: Colors.blue),
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

              return Card(
                elevation: 3,
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text("Outfit ${index + 1}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: outfit.clothes.map((cloth) {
                          return CachedNetworkImage(
                            imageUrl: cloth.imageUrl!,
                            width: 80,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: Icon(Icons.thumb_up,
                                color:
                                    outfit.liked ? Colors.green : Colors.grey),
                            onPressed: () =>
                                updateOutfitLikeStatus(outfit.outfitId!, true),
                          ),
                          IconButton(
                            icon: Icon(Icons.thumb_down,
                                color: outfit.liked == false
                                    ? Colors.redAccent
                                    : Colors.grey),
                            onPressed: () =>
                                updateOutfitLikeStatus(outfit.outfitId!, false),
                          ),
                        ],
                      ),
                    ],
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
