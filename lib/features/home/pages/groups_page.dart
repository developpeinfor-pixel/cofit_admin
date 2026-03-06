import 'package:flutter/material.dart';

import '../widgets/section_header.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({
    super.key,
    required this.groups,
    required this.onAdd,
    required this.onDelete,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> groups;
  final VoidCallback onAdd;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final Color green;
  final bool saving;

  String s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;
  int n(dynamic v) => int.tryParse(s(v, '0')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Groupes',
          subtitle: 'Phase de poules de la competition',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.add,
          color: green,
        ),
        if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Aucun groupe cree pour le moment.'),
          ),
        ...groups.map((group) {
          final teamRows = (group['teams'] is List ? group['teams'] : const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          return Container(
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E4EA)),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD33D),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s(group['name'], 'Groupe'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        onPressed: saving ? null : () => onDelete(group),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1D),
                    ),
                    columns: const [
                      DataColumn(label: Text('Equipes')),
                      DataColumn(label: Text('MJ')),
                      DataColumn(label: Text('G')),
                      DataColumn(label: Text('N')),
                      DataColumn(label: Text('P')),
                      DataColumn(label: Text('BM')),
                      DataColumn(label: Text('BE')),
                      DataColumn(label: Text('DB')),
                      DataColumn(label: Text('Pts')),
                    ],
                    rows: teamRows.map((row) {
                      final team = row['team'] is Map
                          ? Map<String, dynamic>.from(row['team'] as Map)
                          : <String, dynamic>{};
                      final logo = s(team['logo_url']);
                      final teamName = s(team['name'], 'Equipe');
                      final rank = n(row['rank']);

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: Row(
                                children: [
                                  Text(
                                    '$rank.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F6F8),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: logo.isEmpty
                                        ? const Icon(
                                            Icons.shield_outlined,
                                            size: 18,
                                          )
                                        : Image.network(
                                            logo,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.shield_outlined,
                                                  size: 18,
                                                ),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      teamName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text('${n(row['mj'])}')),
                          DataCell(Text('${n(row['g'])}')),
                          DataCell(Text('${n(row['n'])}')),
                          DataCell(Text('${n(row['p'])}')),
                          DataCell(Text('${n(row['bm'])}')),
                          DataCell(Text('${n(row['be'])}')),
                          DataCell(Text('${n(row['db'])}')),
                          DataCell(
                            Text(
                              '${n(row['pts'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
