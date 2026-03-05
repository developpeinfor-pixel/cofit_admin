import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class CompetitionsPage extends StatelessWidget {
  const CompetitionsPage({
    super.key,
    required this.competitions,
    required this.onAdd,
    required this.onDelete,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> competitions;
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
          title: 'Competitions',
          subtitle: 'Nom, saison, lieu, banniere image',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.add,
          color: green,
        ),
        ...competitions.map(
          (e) => CardItem(
            title: '${s(e['name'])} (${s(e['season'])})',
            subtitle: s(e['location'], 'Lieu non defini'),
            deleteDisabled: saving,
            onDelete: () => onDelete(e),
          ),
        ),
      ],
    );
  }
}
