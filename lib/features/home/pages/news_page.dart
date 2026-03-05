import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({
    super.key,
    required this.news,
    required this.onAdd,
    required this.onDelete,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> news;
  final VoidCallback onAdd;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final Color green;
  final bool saving;

  String s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Actualites',
          subtitle: 'Images JPG/JPEG/PNG uniquement',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.add,
          color: green,
        ),
        ...news.map(
          (e) => CardItem(
            title: s(e['title']),
            subtitle: 'Publie: ${e['is_published'] == true ? "oui" : "non"}',
            deleteDisabled: saving,
            onDelete: () => onDelete(e),
          ),
        ),
      ],
    );
  }
}
