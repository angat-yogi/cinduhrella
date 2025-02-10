import 'package:flutter/material.dart';
import 'package:cinduhrella/models/social/post.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:get_it/get_it.dart';

class CreatePostPage extends StatefulWidget {
  final UserProfile currentUser;

  const CreatePostPage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;

  List<StyledOutfit> selectedOutfits = [];
  List<Cloth> selectedClothes = [];
  List<StyledOutfit> availableOutfits = [];
  List<Cloth> availableClothes = [];

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _fetchClothes();
    _fetchOutfits();
  }

  Future<void> _fetchClothes() async {
    try {
      Map<String, List<Map<String, dynamic>>> clothesData =
          await _databaseService.fetchUserItems(widget.currentUser.uid!);

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
      List<StyledOutfit> fetchedOutfits =
          await _databaseService.fetchStyledOutfits(widget.currentUser.uid!);

      setState(() {
        availableOutfits = fetchedOutfits;
      });
    } catch (e) {
      print("Error fetching outfits: $e");
    }
  }

  void _submitPost() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Title and description cannot be empty!")),
      );
      return;
    }

    Post newPost = Post(
      postId: UniqueKey().toString(),
      uid: widget.currentUser.uid,
      title: _titleController.text,
      description: _descriptionController.text,
      outfits: selectedOutfits,
      clothes: selectedClothes,
      likes: [],
      comments: [],
      timestamp: DateTime.now(),
    );

    await _databaseService.addPost(newPost);
    Navigator.pop(context, newPost);
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
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
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
      appBar: AppBar(title: Text("Create New Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            const Text("Select Clothes"),
            SizedBox(
              height: 120,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableClothes
                      .map((cloth) => _buildItemBox(cloth, selectedClothes))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Select Outfits"),
            SizedBox(
              height: 120,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableOutfits
                      .map((outfit) => _buildItemBox(outfit, selectedOutfits))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPost,
              child: Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}
