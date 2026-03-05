import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({
    super.key,
    required this.teams,
    required this.onAdd,
    required this.onDelete,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> teams;
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
          title: 'Equipes',
          subtitle: 'Nom, logo, joueurs et staff en JSON',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.add,
          color: green,
        ),
        ...teams.map(
          (e) => CardItem(
            title: s(e['name']),
            subtitle:
                'Joueurs: ${e['players'] is List ? (e['players'] as List).length : 0} | Staff: ${e['staff'] is List ? (e['staff'] as List).length : 0}',
            deleteDisabled: saving,
            onDelete: () => onDelete(e),
          ),
        ),
      ],
    );
  }
}
