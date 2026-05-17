import 'package:flutter/material.dart';

const String _fallbackProfileAsset = 'assets/images/logo.png';

bool _isUsableRemoteProfile(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return false;
  }
  final parsed = Uri.tryParse(imageUrl);
  if (parsed == null || !(parsed.isScheme('http') || parsed.isScheme('https'))) {
    return false;
  }
  if (parsed.host == 'example.com') {
    return false;
  }
  return true;
}

ImageProvider<Object> profileImageProvider(String? imageUrl) {
  if (_isUsableRemoteProfile(imageUrl)) {
    return NetworkImage(imageUrl!);
  }
  return const AssetImage(_fallbackProfileAsset);
}

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: profileImageProvider(imageUrl),
    );
  }
}
