import 'package:cinduhrella/models/draft_cloth.dart';
import 'package:flutter/material.dart';

class DraftItemCard extends StatelessWidget {
  final DraftCloth draft;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;

  const DraftItemCard({
    super.key,
    required this.draft,
    required this.onConfirm,
    required this.onDismiss,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    draft.imageUrl,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 96,
                      height: 96,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.checkroom),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.type ?? 'Unknown item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          draft.brand,
                          draft.color,
                          draft.size,
                        ]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join(' • '),
                      ),
                      const SizedBox(height: 4),
                      Text(draft.description ?? 'No description'),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          'Confidence ${(draft.confidence * 100).round()}%',
                        ),
                      ),
                      if (draft.source ==
                          DraftItemSource.ownerPhotoLibrary) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Owner match ${(draft.ownerMatchConfidence * 100).round()}%',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (draft.importContext.trim().isNotEmpty)
                          Text(
                            draft.importContext,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    child: const Text('Confirm'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Fix'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    child: const Text('Not Mine'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
