import 'package:flutter/material.dart';
import 'package:cinduhrella/models/cloth.dart';

class PlaygroundWidget extends StatelessWidget {
  final List<Cloth> selectedItems;
  final Function(Cloth) onAddItem;
  final Function(Cloth) onRemoveItem;

  const PlaygroundWidget({
    Key? key,
    required this.selectedItems,
    required this.onAddItem,
    required this.onRemoveItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 1), // Add space at the top
        Center(
          child: DragTarget<Cloth>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: 210,
                height: 440,
                color: const Color.fromARGB(255, 241, 237, 237),
                child: selectedItems.isNotEmpty
                    ? Stack(
                        alignment: Alignment.center,
                        children: selectedItems.map((cloth) {
                          return Positioned(
                            top: 10,
                            left: selectedItems.indexOf(cloth) * 60.0 -
                                (selectedItems.length - 1) * 30.0,
                            child: GestureDetector(
                              onDoubleTap: () => onRemoveItem(cloth),
                              child: Image.network(
                                cloth.imageUrl ?? '',
                                width: 200,
                                height: 200,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : const Center(
                        child: Text(
                          'Select or drag items here to style',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
              );
            },
          ),
        ),
        //const SizedBox(height: 20), // Spacer to ensure layout stability
      ],
    );
  }
}
