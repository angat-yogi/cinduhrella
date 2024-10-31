import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/widgets/playground.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class StylePage extends StatefulWidget {
  const StylePage({super.key});
  @override
  StylePageState createState() => StylePageState();
}

class StylePageState extends State<StylePage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late AlertService _alertService;
  late DatabaseService _databaseService;

  List<Cloth> selectedItems = [];
  List<Cloth> tops = [];
  List<Cloth> bottoms = [];
  List<Cloth> accessories = [];
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    
    _loadClothes();
  }

  Future<void> _loadClothes() async {
  final userId = _authService.user!.uid;

  try {
    _databaseService.getClothesByUidAndType(userId, 'Top').listen((topsData) {
      setState(() {
        tops = topsData;
        isDataLoaded = tops.isNotEmpty || bottoms.isNotEmpty || accessories.isNotEmpty; 
      });
    });

    _databaseService.getClothesByUidAndType(userId, 'Bottom').listen((bottomsData) {
      setState(() {
        bottoms = bottomsData;
        isDataLoaded = tops.isNotEmpty || bottoms.isNotEmpty || accessories.isNotEmpty;
      });
    });

    _databaseService.getClothesByUidAndType(userId, 'Accessories').listen((accessoriesData) {
      setState(() {
        accessories = accessoriesData;
        isDataLoaded = tops.isNotEmpty || bottoms.isNotEmpty || accessories.isNotEmpty;
      });
    });
  } catch (error) {
    _alertService.showToast(text: 'Error loading clothes: $error', icon: Icons.error);
  }
}


  void addSelectedItem(Cloth cloth) {
    if (isDataLoaded) {
      setState(() {
        if (selectedItems.length < 3) {
          selectedItems.add(cloth);
          removeItemFromCategoryBucket(cloth, cloth.type!);
        } else {
          _alertService.showToast(text: 'You can only add up to 3 items.', icon: Icons.error);
        }
      });
    }
  }

 void removeItemFromCategoryBucket(Cloth cloth, String type) {
  switch (type) {
    case "Top":
      tops.remove(cloth);
      break;
    case "Bottom":
      bottoms.remove(cloth);
      break;
    case "Accessories":
      accessories.remove(cloth);
      break;
    default:
      _alertService.showToast(text: 'Unknown cloth type: $type', icon: Icons.error);
      break;
  }
}

void addItemToCategoryBucket(Cloth cloth, String type) {
  switch (type) {
    case "Top":
      tops.add(cloth);
      break;
    case "Bottom":
      bottoms.add(cloth);
      break;
    case "Accessories":
      accessories.add(cloth);
      break;
    default:
      _alertService.showToast(text: 'Unknown cloth type: $type', icon: Icons.error);
      break;
  }
}

  void removeSelectedItem(Cloth cloth) {
    if (isDataLoaded) {
      setState(() {
        selectedItems.remove(cloth);
        addItemToCategoryBucket(cloth, cloth.type!);
      });
    }
  }

  Widget _buildClothItem(Cloth cloth) {
    return Draggable<Cloth>(
      data: cloth,
      feedback: Image.network(
        cloth.imageUrl ?? '',
        fit: BoxFit.scaleDown,
        width: 100,
        height: 100,
      ),
      child: GestureDetector(
        onTap: () => addSelectedItem(cloth),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                cloth.imageUrl ?? '',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      toolbarHeight: 0,
      elevation: 0,
    ),
    body: Column(
      children: [
        // The main content area wrapped in an Expanded widget
        Expanded(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                // Left scroll view with "Top" header
                Positioned(
                  left: 0,
                  top: 20,
                  bottom: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25, // Set width for left column
                    child: Column(
                      children: [
                        const Text('Top', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            itemCount: tops.length,
                            itemBuilder: (context, index) {
                              return _buildClothItem(tops[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right scroll view with "Bottom" header
                Positioned(
                  right: 0,
                  top: 20,
                  bottom: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25, // Set width for right column
                    child: 
                    Column(
                      children: [
                        const Text('Bottom', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            itemCount: bottoms.length,
                            itemBuilder: (context, index) {
                              return _buildClothItem(bottoms[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Playground widget with selected items
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const SizedBox(height: 50), // Space at the top
                      PlaygroundWidget(
                        selectedItems: selectedItems,
                        onAddItem: addSelectedItem,
                        onRemoveItem: removeSelectedItem,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom horizontal scroll view with "Accessories" header
       Column(
          children: [
            const Text('Accessories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
                decoration: const BoxDecoration(
                  border:  Border(
                    top:  BorderSide(color: Colors.grey, width: 2), // Top border
                    bottom:   BorderSide(color: Colors.grey, width: 2), // Bottom border
                  ),
                ),
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                scrollDirection: Axis.horizontal,
                itemCount: accessories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: _buildClothItem(accessories[index]),
                  );
                },
              ),
            ),
            ),
          ],
        ),
      ],
    ),
  );
}


}
