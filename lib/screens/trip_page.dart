import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/models/trip.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:cinduhrella/shared/roadmap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TripPage extends StatefulWidget {
  final String userId;

  const TripPage({required this.userId, super.key});

  @override
  _TripPageState createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripForm,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ✅ Stream to Fetch & Display Trips
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users/${widget.userId}/trips')
                  .orderBy('fromDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No trips added yet!"));
                }

                List<Trip> trips = snapshot.data!.docs
                    .map((trip) => Trip.fromFirestore(trip))
                    .toList();

                return _buildRoadmapWithTrips(trips);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapWithTrips(List<Trip> trips) {
    if (trips.isEmpty) {
      return const Center(child: Text("No trips available."));
    }

    // Sort trips: past trips at the bottom, future trips at the top
    trips.sort((a, b) => b.fromDate.compareTo(a.fromDate));

    DateTime now = DateTime.now();

    return SingleChildScrollView(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // **Roadmap Background Covering Full Width**
          Positioned.fill(
            child: CustomPaint(
              size: Size(double.infinity, trips.length * 250),
              painter: Roadmap(trips.length),
            ),
          ),

          // **Scrollable Trips Positioned in the Center**
          Column(
            children: trips.asMap().entries.map((entry) {
              int index = entry.key;
              Trip trip = entry.value;
              DateTime startDate = trip.fromDate.toDate();
              DateTime endDate = trip.throughDate.toDate();
              int tripDays = endDate.difference(startDate).inDays + 1;
              bool isPastTrip = endDate.isBefore(now);

              return Padding(
                padding: EdgeInsets.only(
                  left: index % 2 == 0 ? 60 : 0, // Adjust for better centering
                  right: index % 2 == 0 ? 0 : 60,
                  bottom: 50,
                ),
                child: Align(
                  alignment: index % 2 == 0
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPastTrip ? Colors.grey[300] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trip.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              trip.imageUrl!,
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              color: isPastTrip
                                  ? Colors.white.withAlpha((0.5 * 255).toInt())
                                  : null,
                              colorBlendMode: isPastTrip
                                  ? BlendMode.modulate
                                  : BlendMode.srcOver,
                            ),
                          ),
                        const SizedBox(height: 5),

                        // **Trip Name**
                        Text(
                          trip.tripName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isPastTrip ? Colors.grey[600] : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),

                        // **Better Date Display**
                        Text(
                          "📅 ${startDate.day}/${startDate.month}/${startDate.year}",
                          style: TextStyle(
                            fontSize: 10,
                            color: isPastTrip ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                        Text(
                          "📅 ${endDate.day}/${endDate.month}/${endDate.year}",
                          style: TextStyle(
                            fontSize: 10,
                            color: isPastTrip ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // **Trip Duration**
                        Text(
                          "🗓️ $tripDays days",
                          style: TextStyle(
                            fontSize: 10,
                            color: isPastTrip ? Colors.grey[600] : Colors.black,
                          ),
                        ),

                        // **Number of Clothes & Outfits**
                        Text(
                          "👗 ${trip.items.length} clothes",
                          style: TextStyle(
                            fontSize: 10,
                            color: isPastTrip ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                        Text(
                          "👕 ${trip.outfits.length} outfits",
                          style: TextStyle(
                            fontSize: 10,
                            color: isPastTrip ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  final DatabaseService databaseService = DatabaseService();
  TextEditingController tripNameController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;
  String? _selectedImageUrl;
  List<StyledOutfit> selectedOutfits = [];
  List<Cloth> selectedClothes = [];
  List<Cloth> availableClothes = [];
  List<StyledOutfit> availableOutfits = [];

  @override
  void initState() {
    super.initState();
    _fetchClothes();
    _fetchOutfits();
  }

  Future<void> _fetchClothes() async {
    try {
      Map<String, List<Map<String, dynamic>>> clothesData =
          await databaseService.fetchUserItems(widget.userId);
      setState(() {
        availableClothes = clothesData.values.expand((e) {
          return e.map((item) => Cloth.fromMap(item));
        }).toList();
      });
    } catch (e) {
      print("Error fetching clothes: $e");
    }
  }

  Future<void> _fetchOutfits() async {
    try {
      List<StyledOutfit> outfits =
          await databaseService.fetchStyledOutfits(widget.userId);
      setState(() {
        availableOutfits = outfits;
      });
    } catch (e) {
      print("Error fetching outfits: $e");
    }
  }

  Future<void> _pickImage(Function(void Function()) updateUI) async {
    await showDialog(
      context: context,
      builder: (context) {
        return ImagePickerDialog(
          userId: widget.userId,
          pathType: "trips",
          onImagePicked: (imageUrl) {
            updateUI(() {
              _selectedImageUrl = imageUrl;
            });
          },
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context, bool isFromDate,
      Function(void Function()) updateUI) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (fromDate ?? DateTime.now())
          : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      updateUI(() {
        if (isFromDate) {
          fromDate = pickedDate;
        } else {
          toDate = pickedDate;
        }
      });
    }
  }

  Future<void> _saveTrip() async {
    if (tripNameController.text.isEmpty || fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    Trip newTrip = Trip(
      tripName: tripNameController.text.trim(),
      fromDate: Timestamp.fromDate(fromDate!),
      throughDate: Timestamp.fromDate(toDate!),
      imageUrl: _selectedImageUrl,
      outfits: selectedOutfits,
      items: selectedClothes,
    );

    await FirebaseFirestore.instance
        .collection('users/${widget.userId}/trips')
        .add(newTrip.toJson());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trip added successfully!")),
    );

    Navigator.pop(context);

    setState(() {
      tripNameController.clear();
      fromDate = null;
      toDate = null;
      _selectedImageUrl = null;
      selectedOutfits.clear();
      selectedClothes.clear();
    });
  }

  void _toggleSelection<T>(
      List<T> selectedList, T item, Function(void Function()) updateUI) {
    updateUI(() {
      if (selectedList.contains(item)) {
        selectedList.remove(item);
      } else {
        selectedList.add(item);
      }
    });
  }

  void _showAddTripForm() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Add New Trip",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: tripNameController,
                        decoration:
                            const InputDecoration(labelText: "Trip Name"),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedImageUrl != null)
                        Image.network(
                          _selectedImageUrl!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await _pickImage(setDialogState);
                        },
                        child: const Text("Select Image"),
                      ),
                      const SizedBox(height: 10),

                      // **From & To Date in the same row**
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                await _pickDate(context, true, setDialogState);
                              },
                              child: Text(
                                fromDate != null
                                    ? "From: ${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}"
                                    : "Pick From Date",
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                await _pickDate(context, false, setDialogState);
                              },
                              child: Text(
                                toDate != null
                                    ? "To: ${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}"
                                    : "Pick To Date",
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // **Scrollable Clothes Selection**
                      const Text("Select Clothes"),
                      SizedBox(
                        height: 120,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableClothes
                                .map((cloth) => _buildItemBox(
                                    cloth, selectedClothes, setDialogState))
                                .toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // **Scrollable Outfits Selection**
                      const Text("Select Outfits"),
                      SizedBox(
                        height: 120,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableOutfits
                                .map((outfit) => _buildItemBox(
                                    outfit, selectedOutfits, setDialogState))
                                .toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveTrip,
                        child: const Text("Save Trip"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemBox<T>(
      T item, List<T> selectedItems, Function(void Function()) updateUI) {
    final isSelected = selectedItems.contains(item);
    final imageUrl = item is Cloth
        ? item.imageUrl
        : (item as StyledOutfit).clothes[0].imageUrl!;
    final title =
        item is Cloth ? item.description : (item as StyledOutfit).name;

    return GestureDetector(
      onTap: () => _toggleSelection(selectedItems, item, updateUI),
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
                ? Image.network(imageUrl,
                    height: 80, width: 80, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 40, color: Colors.grey),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                title ?? "Unknown",
                textAlign: TextAlign.center,
                maxLines: 1, // Ensures the text is only one line
                overflow: TextOverflow.ellipsis, // Trims text and adds "..."
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
