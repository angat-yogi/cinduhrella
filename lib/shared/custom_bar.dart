import 'package:cinduhrella/shared/search_page.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String profileImageUrl;
  final String searchHint;

  const CustomAppBar({
    required this.userName,
    required this.profileImageUrl,
    required this.searchHint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEDE7F6), // ✅ Light Purple Background
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20), // ✅ Smooth bottom curve
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(profileImageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hello, $userName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              readOnly: true,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(114);
}
