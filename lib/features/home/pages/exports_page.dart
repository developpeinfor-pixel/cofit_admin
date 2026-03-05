import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class ExportsPage extends StatelessWidget {
  const ExportsPage({
    super.key,
    required this.onExportCsv,
    required this.onExportPdf,
    required this.standings,
    required this.green,
    required this.saving,
  });

  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;
  final List<Map<String, dynamic>> standings;
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
          title: 'Exports',
          subtitle: 'Statistiques Excel (CSV) et PDF',
          onPressed: () {},
          buttonLabel: 'Pret',
          icon: Icons.check_circle,
          color: green,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            FilledButton.icon(
              onPressed: saving ? null : onExportCsv,
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.table_chart),
              label: const Text('Exporter CSV'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : onExportPdf,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B4F2A),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exporter PDF'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Contraintes appliquees: images JPG/JPEG/PNG, videos MP4 <= 500MB.',
          style: TextStyle(color: Color(0xFF3D7254)),
        ),
        const SizedBox(height: 12),
        ...standings.map(
          (e) => CardItem(
            title: 'Team ${short(s(e['team_id']))}',
            subtitle: 'Pts ${s(e['points'])} | MJ ${s(e['played'])}',
          ),
        ),
      ],
    );
  }
}
