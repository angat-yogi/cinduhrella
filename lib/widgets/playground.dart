import 'package:flutter/material.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/widgets/accessories.dart';
import 'package:cinduhrella/widgets/botttom_wear.dart';
import 'package:cinduhrella/widgets/top_wear.dart';

class PlaygroundWidget extends StatelessWidget {
  final List<Cloth> selectedItems;
  final Function(Cloth) onAddItem;
  final Function(Cloth) onRemoveItem;

  const PlaygroundWidget({
    super.key,
    required this.selectedItems,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  List<Cloth> _getSelectedTop() {
    return selectedItems.where((cloth) => cloth.type == 'Top').toList();
  }

  List<Cloth> _getSelectedBottom() {
    return selectedItems.where((cloth) => cloth.type == 'Bottom').toList();
  }

  List<Cloth> _getSelectedAccessory() {
    return selectedItems.where((cloth) => cloth.type == 'Accessories').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 1),
            TopWearWidget(
              selectedItems: _getSelectedTop(),
              onRemoveItem: onRemoveItem,
            ),
            BottomWearWidget(
              selectedItems: _getSelectedBottom(),
              onRemoveItem: onRemoveItem,
            ),
            AccessoriesWidget(
            selectedItems: _getSelectedAccessory(),
            onRemoveItem: onRemoveItem,
          ),
          ],
        ),
        // Positioned(
        //   right: 0,
        //   top: 0,
        //   child: AccessoriesWidget(
        //     selectedItems: _getSelectedAccessory(),
        //     onRemoveItem: onRemoveItem,
        //   ),
        // ),
      ],
    );
  }
}
