import 'package:flutter/material.dart';
import 'package:cinduhrella/models/cloth.dart';

class AccessoriesWidget extends StatefulWidget {
  final List<Cloth> selectedItems;
  final Function(Cloth) onRemoveItem;

  const AccessoriesWidget({
    super.key,
    required this.selectedItems,
    required this.onRemoveItem,
  });

  @override
  _AccessoriesWidgetState createState() => _AccessoriesWidgetState();
}

class _AccessoriesWidgetState extends State<AccessoriesWidget> {
  // To track the position of each accessory
  Map<int, Offset> positions = {};

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DragTarget<Cloth>(
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: 210,
            height: 110,
            color: const Color.fromARGB(255, 241, 237, 237),
            child: widget.selectedItems.isNotEmpty
                ? Stack(
                    alignment: Alignment.center,
                    children: widget.selectedItems.map((cloth) {
                      int index = widget.selectedItems.indexOf(cloth);
                      return Positioned(
                        top: positions[index]?.dy ?? 0,
                        left: positions[index]?.dx ?? 0,
                        child: Draggable<Cloth>(
                          data: cloth,
                          feedback: Opacity(
                            opacity: 0.5,
                            child: Image.network(
                              cloth.imageUrl ?? '',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          childWhenDragging: Container(), // Hide original when dragging
                          onDragEnd: (details) {
                            setState(() {
                              // Calculate the position relative to the widget
                              RenderBox renderBox = context.findRenderObject() as RenderBox;
                              Offset localPosition = renderBox.globalToLocal(details.offset);

                              // Determine the new position while ensuring the image stays within bounds
                              double newX = localPosition.dx - 50; // Center image based on its width
                              double newY = localPosition.dy - 50; // Center image based on its height

                              // Constraints to keep the image fully visible within the widget
                              newX = newX.clamp(0.0, 210.0 - 100.0); // Ensure the image fits within the width
                              newY = newY.clamp(0.0, 110.0 - 100.0); // Ensure the image fits within the height

                              // Update the position where the accessory was dropped
                              positions[index] = Offset(newX, newY);
                            });
                          },
                          child: GestureDetector(
                            onDoubleTap: () => widget.onRemoveItem(cloth),
                            child: Image.network(
                                cloth.imageUrl ?? '',
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Center(
                    child: Text(
                      'Select or drag accessories here',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
