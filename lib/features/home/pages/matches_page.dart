import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({
    super.key,
    required this.matches,
    required this.onAdd,
    required this.onDelete,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> matches;
  final VoidCallback onAdd;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final Color green;
  final bool saving;

  String s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;
  String short(String id) => id.length <= 8 ? id : id.substring(0, 8);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Matchs + Stats',
          subtitle: 'Arbitres, compos, stats avancees en JSON',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.add,
          color: green,
        ),
        ...matches.map(
          (e) => CardItem(
            title: '${short(s(e['home_team_id']))} vs ${short(s(e['away_team_id']))}',
            subtitle:
                '${s(e['match_date'])} | ${s(e['status'])} | score ${s(e['home_score'])}-${s(e['away_score'])}',
            deleteDisabled: saving,
            onDelete: () => onDelete(e),
          ),
        ),
      ],
    );
  }
}
