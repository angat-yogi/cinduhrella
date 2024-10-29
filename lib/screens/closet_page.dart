import 'package:cinduhrella/widgets/add_item.dart';
import 'package:flutter/material.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  final List<Map<String, String>> clothes = [
    {
      'image': 'https://i5.walmartimages.com/seo/Gildan-Unisex-Youth-T-Shirt-red-xs-4-5-Little-Girls_4d2c5a4e-5769-436e-a29d-36132b3295c3_1.ad0a6f0634c83d1d411f9032fcb019f1.jpeg',
      'description': 'Casual Shirt',
      'brand': 'Brand A'
    },
    {
      'image': 'https://i5.walmartimages.com/seo/Gildan-Unisex-Youth-T-Shirt-red-xs-4-5-Little-Girls_4d2c5a4e-5769-436e-a29d-36132b3295c3_1.ad0a6f0634c83d1d411f9032fcb019f1.jpeg',
      'description': 'Formal Shirt',
      'brand': 'Brand B'
    },
    // More items...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddItemForm(),
                ),
              ).then((value) {
                // Optionally handle any return data or refresh state if needed
                setState(() {}); // This ensures the ClosetPage rebuilds if needed
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.75,
          ),
          itemCount: clothes.length,
          itemBuilder: (context, index) {
            final item = clothes[index];
            return _buildClothingItem(
              image: item['image']!,
              description: item['description']!,
              brand: item['brand']!,
            );
          },
        ),
      ),
    );
  }

  Widget _buildClothingItem({
    required String image,
    required String description,
    required String brand,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  brand,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}