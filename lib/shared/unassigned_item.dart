import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ClosetItemsSection extends StatelessWidget {
  ClosetItemsSection({super.key});

  final DatabaseService _databaseService =
      GetIt.instance.get<DatabaseService>();
  final String _userId = GetIt.instance.get<AuthService>().user!.uid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Closet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _databaseService.getClosetItemsStream(_userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const Text(
                'No closet items yet. Add pieces manually or import them from scans and photos.',
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final imageUrl = (item['imageUrl'] ?? '').toString();
                final title = _titleForItem(item);
                final subtitle = _subtitleForItem(item);
                final type = (item['type'] ?? 'accessories').toString();

                return Card(
                  elevation: 1.5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.black12,
                              child: const Icon(Icons.checkroom_outlined),
                            ),
                    ),
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _colorForType(type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: _colorForType(type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _titleForItem(Map<String, dynamic> item) {
    final displayLabel = (item['displayLabel'] ?? '').toString().trim();
    if (displayLabel.isNotEmpty) {
      return displayLabel;
    }
    final description = (item['description'] ?? '').toString().trim();
    if (description.isNotEmpty) {
      return description;
    }
    final brand = (item['brand'] ?? '').toString().trim();
    if (brand.isNotEmpty) {
      return brand;
    }
    return 'Closet item';
  }

  String _subtitleForItem(Map<String, dynamic> item) {
    final brand = (item['brand'] ?? '').toString().trim();
    final color = (item['color'] ?? '').toString().trim();
    final size = (item['size'] ?? '').toString().trim();
    final parts =
        [brand, color, size].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Ready in your closet' : parts.join(' • ');
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'top wear':
        return const Color(0xFFDB6C63);
      case 'bottom wear':
        return const Color(0xFF4D6CFA);
      default:
        return const Color(0xFF10A37F);
    }
  }
}

class UnassignedItemsSection extends StatelessWidget {
  const UnassignedItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ClosetItemsSection();
  }
}
