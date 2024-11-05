import 'package:flutter/material.dart';
import 'package:cinduhrella/models/cloth.dart';

class TopWearWidget extends StatelessWidget {
  final List<Cloth> selectedItems;
  final Function(Cloth) onRemoveItem;

  const TopWearWidget({
    super.key,
    required this.selectedItems,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = selectedItems.length;
    const itemWidth = 150.0; // Width of each item
    const itemHeight = 150.0; // Height of each item

    // Calculate total width needed for the items
    final totalWidth = itemCount > 0 ? itemCount * itemWidth : 210.0;
    const containerHeight = itemHeight*0.9; // Set container height to item height

    return Center(
      child: DragTarget<Cloth>(
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: totalWidth < 210 ? 210 : totalWidth, // Ensure a minimum width
            height: containerHeight,
            color: const Color.fromARGB(255, 241, 237, 237),
            child: selectedItems.isNotEmpty
                ? Stack(
                    alignment: Alignment.center,
                    children: selectedItems.map((cloth) {
                      return Positioned(
                        top: 0,
                        left: (selectedItems.indexOf(cloth) * itemWidth) -
                            (totalWidth / 2 - itemWidth /1.5),
                        child: GestureDetector(
                          onDoubleTap: () => onRemoveItem(cloth),
                          child: Image.network(
                            cloth.imageUrl ?? '',
                            width: itemWidth,
                            height: itemHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Center(
                    child: Text(
                      'Select or drag top wear here',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
