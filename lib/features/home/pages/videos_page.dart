import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class VideosPage extends StatelessWidget {
  const VideosPage({
    super.key,
    required this.videos,
    required this.onAdd,
    required this.onDelete,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> videos;
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
          title: 'Videos/Interviews',
          subtitle: 'Format MP4 et taille <= 500MB',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.add,
          color: green,
        ),
        ...videos.map(
          (e) => CardItem(
            title: '${s(e['title'])} (${s(e['type'])})',
            subtitle: 'Taille: ${s(e['video_size_mb'], '-')} MB',
            deleteDisabled: saving,
            onDelete: () => onDelete(e),
          ),
        ),
      ],
    );
  }
}
