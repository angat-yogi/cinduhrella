import 'package:flutter/material.dart';

class StyledOutfitWidget extends StatelessWidget {
  final String topWearImage;
  final String bottomWearImage;
  final String? leftAccessoryImage;
  final String? rightAccessoryImage;
  final String outfitName;

  const StyledOutfitWidget({
    super.key,
    required this.topWearImage,
    required this.bottomWearImage,
    this.leftAccessoryImage,
    this.rightAccessoryImage,
    required this.outfitName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 250, // 🔥 Reduced height slightly to fix overflow
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4), // 🔥 Less padding
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ Outfit Name (🔥 No extra space)
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2), // 🔥 Reduced padding
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.9), // 🔥 Background for readability
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                outfitName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ✅ Top Wear (🔥 Snugly below Outfit Name)
          Positioned(
            top: 18, // 🔥 Moved slightly up
            child: _buildItemImage(topWearImage, 95, 110), // 🔥 Slightly bigger
          ),

          // ✅ Bottom Wear (🔥 Now equal/larger than Top Wear)
          Positioned(
            bottom: 0, // 🔥 No extra bottom space
            child: _buildItemImage(
                bottomWearImage, 100, 115), // 🔥 Slightly larger
          ),

          // ✅ Left Accessory
          if (leftAccessoryImage != null)
            Positioned(
              left: 5,
              top: 80,
              child: _buildItemImage(leftAccessoryImage!, 35, 35),
            ),

          // ✅ Right Accessory
          if (rightAccessoryImage != null)
            Positioned(
              right: 5,
              top: 80,
              child: _buildItemImage(rightAccessoryImage!, 35, 35),
            ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String imageUrl, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.contain, // 🔥 Ensures image doesn't exceed bounds
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/placeholder.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
