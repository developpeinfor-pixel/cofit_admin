import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class SeasonsPage extends StatelessWidget {
  const SeasonsPage({
    super.key,
    required this.seasons,
    required this.onAdd,
    required this.onDelete,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> seasons;
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
          title: 'Saisons',
          subtitle: 'Creer les saisons de competition',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.add,
          color: green,
        ),
        ...seasons.map(
          (e) => CardItem(
            title: s(e['name']),
            subtitle: '${s(e['start_date'])} -> ${s(e['end_date'])}',
            deleteDisabled: saving,
            onDelete: () => onDelete(e),
          ),
        ),
      ],
    );
  }
}
