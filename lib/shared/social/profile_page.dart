import 'package:flutter/material.dart';
import 'package:cinduhrella/models/social/post.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:get_it/get_it.dart';
import 'package:cinduhrella/shared/social/user_post.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile user;
  final String currentUserId;
  final bool isOwnProfile;

  const ProfilePage({
    Key? key,
    required this.user,
    required this.currentUserId,
    required this.isOwnProfile,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<List<Post>> _userPosts;
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _userPosts = _databaseService.getUserPosts(widget.user.uid!);
  }

  void _editProfile() {
    // ✅ Navigate to Edit Profile Screen (Implement separately)
    print("Edit Profile Clicked!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(""),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ Profile Header Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purpleAccent, Colors.deepPurple],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      widget.user.profilePictureUrl ??
                          "https://example.com/default-profile.png",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.user.fullName ?? "Unknown User",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    "@${widget.user.userName}",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _infoBox("Following", widget.user.followingCount),
                      const SizedBox(width: 20),
                      _infoBox("Followers", widget.user.followersCount),
                      const SizedBox(width: 20),
                      _infoBox("Posts", widget.user.postCount),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ✅ Show "Edit Profile" for self
                  if (widget.isOwnProfile)
                    ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white),
                      child: const Text("Edit Profile",
                          style: TextStyle(color: Colors.black)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Shared Posts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Shared Posts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Post>>(
                    future: _userPosts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "No posts shared yet!",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: PostWidget(
                                post: snapshot.data![index], user: widget.user),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔹 Info Box Widget**
  Widget _infoBox(String label, int count) {
    return Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}
