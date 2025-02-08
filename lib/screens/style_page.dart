import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StylePage extends StatefulWidget {
  final String userId;

  const StylePage({required this.userId, super.key});

  @override
  _StylePageState createState() => _StylePageState();
}

class _StylePageState extends State<StylePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DatabaseService databaseService = DatabaseService();
  List<Map<String, dynamic>> topWear = [];
  List<Map<String, dynamic>> bottomWear = [];
  List<Map<String, dynamic>> accessories = [];
  List<Map<String, dynamic>> selectedItems = [];
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchClothes(); // Fetch data every time the page is revisited
  }

  Future<void> fetchClothes() async {
    setState(() {
      isLoading = true; // Show loading indicator while fetching
    });

    Map<String, List<Map<String, dynamic>>> categorizedItems =
        await databaseService.fetchUserItems(widget.userId);

    setState(() {
      topWear = categorizedItems['top wear'] ?? [];
      bottomWear = categorizedItems['bottom wear'] ?? [];
      accessories = categorizedItems['accessories'] ?? [];
      isLoading = false; // Stop loading indicator
    });
  }

  void toggleItem(Map<String, dynamic> item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
        if (item['type'].toString().toLowerCase() == 'top wear') {
          topWear.add(item);
        } else if (item['type'].toString().toLowerCase() == 'bottom wear') {
          bottomWear.add(item);
        } else {
          accessories.add(item);
        }
      } else {
        selectedItems.add(item);
        if (item['type'].toString().toLowerCase() == 'top wear') {
          topWear.remove(item);
        } else if (item['type'].toString().toLowerCase() == 'bottom wear') {
          bottomWear.remove(item);
        } else {
          accessories.remove(item);
        }
      }
    });
  }

  // Future<void> saveStyledOutfit() async {
  //   if (selectedItems.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Select items before saving!")),
  //     );
  //     return;
  //   }

  //   try {
  //     List<Cloth> clothes = selectedItems.map((item) {
  //       return Cloth(
  //         clothId: item['id'],
  //         storageId: item['storageId'],
  //         uid: widget.userId,
  //         imageUrl: item['imageUrl'],
  //         brand: item['brand'],
  //         size: item['size'],
  //         description: item['description'],
  //         type: item['type'],
  //         color: item['color'],
  //       );
  //     }).toList();

  //     StyledOutfit outfit = StyledOutfit(
  //       uid: widget.userId,
  //       clothes: clothes,
  //       createdAt: Timestamp.now(),
  //     );

  //     String path = 'users/${widget.userId}/styledOutfits';
  //     await firestore.collection(path).add(outfit.toJson());

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Outfit saved successfully!")),
  //     );

  //     setState(() {
  //       selectedItems.clear();
  //     });
  //   } catch (e) {
  //     print("Error saving styled outfit: $e");
  //   }
  // }

  Future<void> saveStyledOutfit() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select items before saving!")),
      );
      return;
    }

    try {
      // ✅ Generate a name from the first words of descriptions
      String generatedName = selectedItems
          .map((item) => (item['description'] ?? '').split(' ').first)
          .join(' ');

      List<Cloth> clothes = selectedItems.map((item) {
        return Cloth(
          clothId: item['id'],
          storageId: item['storageId'],
          uid: widget.userId,
          imageUrl: item['imageUrl'],
          brand: item['brand'],
          size: item['size'],
          description: item['description'],
          type: item['type'],
          color: item['color'],
        );
      }).toList();

      // ✅ Create Firestore document reference
      String path = 'users/${widget.userId}/styledOutfits';
      DocumentReference newOutfitRef =
          firestore.collection(path).doc(); // Create new doc ref

      StyledOutfit outfit = StyledOutfit(
        outfitId: newOutfitRef.id, // ✅ Store generated Firestore ID
        uid: widget.userId,
        name: generatedName.isNotEmpty ? generatedName : 'Unnamed Outfit',
        clothes: clothes,
        createdAt: Timestamp.now(),
      );

      // ✅ Use `.set()` with generated ID instead of `.add()`
      await newOutfitRef.set(outfit.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit saved successfully!")),
      );

      setState(() {
        selectedItems.clear();
      });
    } catch (e) {
      print("Error saving styled outfit: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving outfit: ${e.toString()}")),
      );
    }
  }

  Widget buildClothesColumn(List<Map<String, dynamic>> items, String category) {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index];
                return GestureDetector(
                  onTap: () => toggleItem(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: CachedNetworkImage(
                      imageUrl: item['imageUrl'],
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget buildAccessoriesRow() {
    return SizedBox(
      height: 100,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: accessories.length,
              itemBuilder: (context, index) {
                var item = accessories[index];
                return GestureDetector(
                  onTap: () => toggleItem(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: CachedNetworkImage(
                      imageUrl: item['imageUrl'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget buildStyleBoard() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade200,
      ),
      child: selectedItems.isEmpty
          ? const Center(child: Text("Tap clothes to add here"))
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: selectedItems
                  .map((item) => GestureDetector(
                        onTap: () => toggleItem(item),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            CachedNetworkImage(
                              imageUrl: item['imageUrl'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Style Your Clothes"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchClothes, // Refresh when button is clicked
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Bottom Wear (Left)
                buildClothesColumn(bottomWear, 'bottomWear'),

                // Middle Playground
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        const Text("Style Playground",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        buildStyleBoard(),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: saveStyledOutfit,
                          child: const Text("Save Style"),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Wear (Right)
                buildClothesColumn(topWear, 'topWear'),
              ],
            ),
          ),

          // Accessories (Bottom)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: buildAccessoriesRow(),
          ),
        ],
      ),
    );
  }
}
