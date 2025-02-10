import 'package:cinduhrella/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:cinduhrella/models/social/post.dart';

class PostWidget extends StatelessWidget {
  final Post post;
  final UserProfile user;

  const PostWidget({Key? key, required this.post, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user.profilePictureUrl ??
                      'https://example.com/default-profile.png'),
                  radius: 25,
                ),
                const SizedBox(width: 10),
                Text(
                  user.fullName ?? "Unknown User",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              post.description ?? "No description available",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),

            // Display Outfits & Clothes in Horizontal Scroll
            if ((post.outfits != null && post.outfits!.isNotEmpty) ||
                (post.clothes != null && post.clothes!.isNotEmpty)) ...[
              const Text("Gallery",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 5),
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (post.outfits != null)
                      ...post.outfits!
                          .expand((outfit) =>
                              outfit.clothes.map((cloth) => cloth.imageUrl))
                          .map((imageUrl) => _buildImage(imageUrl)),
                    if (post.clothes != null)
                      ...post.clothes!
                          .map((cloth) => _buildImage(cloth.imageUrl)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Likes & Comments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red),
                    const SizedBox(width: 5),
                    Text("${post.likes?.length ?? 0} Likes"),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.comment, color: Colors.blue),
                    const SizedBox(width: 5),
                    Text("${post.comments?.length ?? 0} Comments"),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Comments Section
            if (post.comments != null && post.comments!.isNotEmpty) ...[
              const Text("Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 5),
              Column(
                children: post.comments!.map((comment) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(comment.userId),
                    ),
                    title: Text(comment.text),
                    subtitle: Text(comment.timestamp.toLocal().toString()),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return SizedBox();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 120,
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
