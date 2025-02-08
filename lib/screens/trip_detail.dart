import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/models/trip.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TripDetailPage extends StatefulWidget {
  final String userId;
  final Trip trip;
  final String tripId;

  const TripDetailPage({
    required this.userId,
    required this.trip,
    required this.tripId,
    super.key,
  });

  @override
  _TripDetailPageState createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late TextEditingController tripNameController;
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedImageUrl;
  List<StyledOutfit> selectedOutfits = [];
  List<Cloth> selectedClothes = [];
  List<Cloth> availableClothes = [];
  List<StyledOutfit> availableOutfits = [];

  late String originalTripName;
  late DateTime? originalFromDate;
  late DateTime? originalToDate;
  late String? originalImageUrl;
  late List<StyledOutfit> originalSelectedOutfits;
  late List<Cloth> originalSelectedClothes;

  final DatabaseService databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    tripNameController = TextEditingController(text: widget.trip.tripName);
    fromDate = widget.trip.fromDate.toDate();
    toDate = widget.trip.throughDate.toDate();
    selectedImageUrl = widget.trip.imageUrl;
    selectedOutfits = List.from(widget.trip.outfits);
    selectedClothes = List.from(widget.trip.items);

    // Backup original data
    originalTripName = widget.trip.tripName;
    originalFromDate = widget.trip.fromDate.toDate();
    originalToDate = widget.trip.throughDate.toDate();
    originalImageUrl = widget.trip.imageUrl;
    originalSelectedOutfits = List.from(widget.trip.outfits);
    originalSelectedClothes = List.from(widget.trip.items);
    _fetchClothes();
    _fetchOutfits();
  }

  void _cancelEdit() {
    setState(() {
      tripNameController.text = originalTripName;
      fromDate = originalFromDate;
      toDate = originalToDate;
      selectedImageUrl = originalImageUrl;
      selectedOutfits = List.from(originalSelectedOutfits);
      selectedClothes = List.from(originalSelectedClothes);
    });

    Navigator.pop(context); // Close the details page without saving changes
  }

  Future<void> _fetchClothes() async {
    try {
      Map<String, List<Map<String, dynamic>>> clothesData =
          await databaseService.fetchUserItems(widget.userId);

      List<Cloth> fetchedClothes = clothesData.values.expand((e) {
        return e.map((item) => Cloth.fromMap(item));
      }).toList();

      setState(() {
        availableClothes = fetchedClothes;

        // Ensure previously selected clothes are still selected
        selectedClothes = availableClothes
            .where((cloth) => widget.trip.items
                .any((selected) => selected.clothId == cloth.clothId))
            .toList();
      });
    } catch (e) {
      print("Error fetching clothes: $e");
    }
  }

  Future<void> _fetchOutfits() async {
    try {
      List<StyledOutfit> fetchedOutfits =
          await databaseService.fetchStyledOutfits(widget.userId);

      setState(() {
        availableOutfits = fetchedOutfits;

        // Ensure previously selected outfits are still selected
        selectedOutfits = availableOutfits
            .where((outfit) => widget.trip.outfits
                .any((selected) => selected.outfitId == outfit.outfitId))
            .toList();
      });
    } catch (e) {
      print("Error fetching outfits: $e");
    }
  }

  Future<void> _pickImage() async {
    await showDialog(
      context: context,
      builder: (context) {
        return ImagePickerDialog(
          userId: widget.userId,
          pathType: "trips",
          onImagePicked: (imageUrl) {
            setState(() {
              selectedImageUrl = imageUrl;
            });
          },
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context, bool isFromDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (fromDate ?? DateTime.now())
          : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          fromDate = pickedDate;
        } else {
          toDate = pickedDate;
        }
      });
    }
  }

  Future<void> _updateTrip() async {
    if (tripNameController.text.isEmpty || fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    Trip updatedTrip = Trip(
      tripName: tripNameController.text.trim(),
      fromDate: Timestamp.fromDate(fromDate!),
      throughDate: Timestamp.fromDate(toDate!),
      imageUrl: selectedImageUrl,
      outfits: selectedOutfits,
      items: selectedClothes,
    );

    await FirebaseFirestore.instance
        .collection('users/${widget.userId}/trips')
        .doc(widget.tripId)
        .update(updatedTrip.toJson());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trip updated successfully!")),
    );

    Navigator.pop(context, updatedTrip);
  }

  void _toggleSelection<T>(List<T> selectedList, T item) {
    setState(() {
      if (selectedList.contains(item)) {
        selectedList.remove(item);
      } else {
        selectedList.add(item);
      }
    });
  }

  Widget _buildItemBox<T>(T item, List<T> selectedItems) {
    final isSelected = selectedItems.contains(item);
    final imageUrl = item is Cloth
        ? item.imageUrl
        : (item as StyledOutfit).clothes[0].imageUrl!;
    final title =
        item is Cloth ? item.description : (item as StyledOutfit).name;

    return GestureDetector(
      onTap: () => _toggleSelection(selectedItems, item),
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey, width: 3),
        ),
        child: Column(
          children: [
            imageUrl != null
                ? AspectRatio(
                    aspectRatio: 16 / 9, // Adjust aspect ratio as needed
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10), // Optional rounded corners
                      child: Image.network(imageUrl!,
                          height: 100, width: 100, fit: BoxFit.cover),
                    ),
                  )
                : const Icon(Icons.image, size: 40, color: Colors.grey),
            const SizedBox(height: 5),
            Text(
              title ?? "Unknown",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: tripNameController,
              decoration: const InputDecoration(labelText: "Trip Name"),
            ),
            const SizedBox(height: 10),
            if (selectedImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  selectedImageUrl!,
                  height: 200, // Increased height
                  width: double.infinity, // Full width
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _pickImage, child: const Text("Select Image")),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () => _pickDate(context, true),
                    child: Text(
                      "From:${fromDate?.toLocal().toString().split(' ')[0]}",
                      overflow: TextOverflow.ellipsis,
                    )),
                TextButton(
                    onPressed: () => _pickDate(context, false),
                    child: Text(
                      "To: ${toDate?.toLocal().toString().split(' ')[0]}",
                      overflow: TextOverflow.ellipsis,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Select Clothes"),
            SizedBox(
                height: 120,
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: availableClothes
                            .map((cloth) =>
                                _buildItemBox(cloth, selectedClothes))
                            .toList()))),
            const SizedBox(height: 10),
            const Text("Select Outfits"),
            SizedBox(
                height: 120,
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: availableOutfits
                            .map((outfit) =>
                                _buildItemBox(outfit, selectedOutfits))
                            .toList()))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _cancelEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300], // Cancel button styling
                  ),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: _updateTrip,
                  child: const Text("Update Trip"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
