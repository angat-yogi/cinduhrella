import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/shared/social/create_post.dart';
import 'package:cinduhrella/shared/social/profile_page.dart';
import 'package:cinduhrella/shared/social/user_post.dart';
import 'package:cinduhrella/shared/search_page.dart';
import 'package:cinduhrella/models/social/post.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class OutfitFeedPage extends StatefulWidget {
  final UserProfile currentUser;

  const OutfitFeedPage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _OutfitFeedPageState createState() => _OutfitFeedPageState();
}

class _OutfitFeedPageState extends State<OutfitFeedPage> {
  late Future<List<Post>> _publicPosts;
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  late AuthService _authService;
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _authService = _getIt.get<AuthService>();
    _publicPosts = _fetchPublicPosts();
  }

  Future<List<Post>> _fetchPublicPosts() async {
    return await _databaseService.getPublicPosts(widget.currentUser.uid!);
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    List<UserProfile> users = await _databaseService.searchUsers(query);
    setState(() {
      _searchResults = users;
    });
  }

  void _addNewPost() async {
    final newPost = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostPage(currentUser: widget.currentUser),
      ),
    );
    if (newPost != null) {
      await _databaseService.addPost(newPost);
      setState(() {
        _publicPosts = _fetchPublicPosts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _searchUsers,
          decoration: InputDecoration(
            hintText: "Search users...",
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPost,
        child: Icon(Icons.add),
      ),
      body: _searchResults.isNotEmpty
          ? _buildSearchResults()
          : FutureBuilder<List<Post>>(
              future: _publicPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text("Failed to load posts. Try again later.",
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }
                final posts = snapshot.data!;
                return posts.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              ListTile(
                                title: Text(posts[index].title ?? "Untitled"),
                                subtitle: Text(posts[index].description ??
                                    "No description"),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: PostWidget(
                                    post: posts[index],
                                    user: widget.currentUser),
                              ),
                            ],
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          "No posts available! Follow people to see their styles.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
              },
            ),
    );
  }

  /// **🔹 Search Results for Users**
  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        UserProfile user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(user.profilePictureUrl ??
                "https://example.com/default-profile.png"),
          ),
          title: Text(user.fullName ?? "Unknown User"),
          subtitle: Text("@${user.userName}"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchPage(searchType: "users"),
              ),
            );
          },
        );
      },
    );
  }

  /// **🔹 Drawer with User Info**
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.currentUser.fullName ?? "Unknown User"),
            accountEmail: Text("@${widget.currentUser.userName ?? "null"}"),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      user: widget.currentUser,
                      currentUserId: widget.currentUser.uid!,
                      isOwnProfile:
                          widget.currentUser.uid! == _authService.user!.uid,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  widget.currentUser.profilePictureUrl ??
                      "https://example.com/default-profile.png",
                ),
              ),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purpleAccent, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text("Following: ${widget.currentUser.followingCount}"),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Followers: ${widget.currentUser.followersCount}"),
          ),
          ListTile(
            leading: Icon(Icons.post_add),
            title: Text("Posts: ${widget.currentUser.postCount}"),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
