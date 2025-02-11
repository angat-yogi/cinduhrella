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
  bool _isFollowing = false;
  late UserProfile _userProfile; // ✅ Local state variable

  void _toggleFollow() async {
    await _databaseService.followUser(widget.currentUserId, _userProfile.uid!);

    // Fetch updated user profile
    UserProfile? updatedUser =
        await _databaseService.getUserProfile(uid: _userProfile.uid!);

    if (updatedUser != null) {
      setState(() {
        _isFollowing = !_isFollowing;
        _userProfile = updatedUser; // ✅ Update UI with new data
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _userProfile = widget.user; // ✅ Store _userProfile in a mutable variable
    if (widget.isOwnProfile) {
      _userPosts = _databaseService.getUserPosts(_userProfile.uid!);
    } else {
      _userPosts = _databaseService.getUserPublicPosts(_userProfile.uid!);
    }
  }

  Stream<UserProfile?> _fetchUserProfile() {
    return _databaseService.getUserProfileStream(_userProfile.uid!);
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
                      _userProfile.profilePictureUrl ??
                          "https://example.com/default-profile.png",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userProfile.fullName ?? "Unknown User",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    "@${_userProfile.userName}",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreamBuilder<UserProfile?>(
                        stream: _fetchUserProfile(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return _infoBox(
                                "Following", snapshot.data!.followingCount);
                          }
                          return _infoBox(
                              "Following", _userProfile.followingCount);
                        },
                      ),
                      const SizedBox(width: 20),
                      StreamBuilder<UserProfile?>(
                        stream: _fetchUserProfile(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return _infoBox(
                                "Followers", snapshot.data!.followersCount);
                          }
                          return _infoBox(
                              "Followers", _userProfile.followersCount);
                        },
                      ),
                      const SizedBox(width: 20),
                      StreamBuilder<UserProfile?>(
                        stream: _fetchUserProfile(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return _infoBox("Posts", snapshot.data!.postCount);
                          }
                          return _infoBox("Posts", _userProfile.postCount);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ✅ Show "Edit Profile" for self
                  widget.isOwnProfile
                      ? ElevatedButton(
                          onPressed: _editProfile,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white),
                          child: const Text("Edit Profile",
                              style: TextStyle(color: Colors.black)),
                        )
                      : ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isFollowing ? Colors.red : Colors.blue,
                          ),
                          child: Text(
                            _isFollowing ? "Unfollow" : "Follow",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
            // ✅ Shared Posts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // ✅ Prevent unnecessary space
                children: [
                  const Text(
                    "Shared Posts", // ✅ Null-safe
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 1),
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
                            padding: EdgeInsets.symmetric(vertical: 10),
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
                        padding: EdgeInsets.zero, // ✅ Remove any extra spacing
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: PostWidget(
                                post: snapshot.data![index],
                                user: _userProfile),
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
