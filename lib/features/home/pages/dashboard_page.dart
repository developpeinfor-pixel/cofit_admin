import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/utils/file_downloader.dart';
import '../widgets/section_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.dashboard,
    required this.onRefresh,
    required this.green,
    required this.canCreateAdmin,
    required this.onCreateAdmin,
  });

  final Map<String, dynamic> dashboard;
  final VoidCallback onRefresh;
  final Color green;
  final bool canCreateAdmin;
  final VoidCallback onCreateAdmin;

  String s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

  bool b(dynamic v) => v == true;

  List<Map<String, dynamic>> teams(dynamic data) => data is List
      ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];

  Future<void> exportTeams(
    BuildContext context,
    List<Map<String, dynamic>> teamRows,
    String format,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (format == 'json') {
      final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(teamRows)),
      );
      await downloadBytes(
        fileName: 'competition-teams-$timestamp.json',
        mimeType: 'application/json',
        bytes: bytes,
      );
      return;
    }

    if (format == 'csv') {
      final header = 'id,name,short_name';
      final lines = teamRows.map((team) {
        final id = s(team['id']).replaceAll('"', '""');
        final name = s(team['name']).replaceAll('"', '""');
        final shortName = s(team['short_name']).replaceAll('"', '""');
        return '"$id","$name","$shortName"';
      });
      final csv = '$header\n${lines.join('\n')}';
      final bytes = Uint8List.fromList(utf8.encode(csv));
      await downloadBytes(
        fileName: 'competition-teams-$timestamp.csv',
        mimeType: 'text/csv',
        bytes: bytes,
      );
      return;
    }

    final lines = [
      'COFIT - Equipes participantes',
      'Date export: ${DateTime.now().toIso8601String()}',
      '',
      ...teamRows.map(
        (team) => '- ${s(team['name'])} (${s(team['short_name'], 'n/a')})',
      ),
    ];
    final pdfLikeText = lines.join('\n');
    final bytes = Uint8List.fromList(utf8.encode(pdfLikeText));
    await downloadBytes(
      fileName: 'competition-teams-$timestamp.pdf',
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  Future<void> showTeamsDialog(
    BuildContext context,
    List<Map<String, dynamic>> teamRows,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Equipes participantes'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92 > 520
              ? 520
              : MediaQuery.of(context).size.width * 0.92,
          child: teamRows.isEmpty
              ? const Text('Aucune equipe liee a la competition en cours.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: teamRows.length,
                        itemBuilder: (_, i) {
                          final team = teamRows[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.shield_outlined),
                            title: Text(s(team['name'])),
                            subtitle: Text('ID: ${s(team['id'])}'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              exportTeams(context, teamRows, 'csv'),
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Exporter CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              exportTeams(context, teamRows, 'json'),
                          icon: const Icon(Icons.data_object),
                          label: const Text('Exporter JSON'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              exportTeams(context, teamRows, 'pdf'),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Exporter PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget statCard(
    BuildContext context,
    String title,
    String value, {
    String? subtitle,
    VoidCallback? onTap,
    double width = 220,
  }) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7ECD9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF44745A))),
          Text(
            value,
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6C8B79), fontSize: 12),
            ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstname = s(dashboard['current_admin_first_name'], 'Admin');
    final currentCompetition = dashboard['current_competition'];
    final competitionName = currentCompetition is Map<String, dynamic>
        ? s(currentCompetition['name'], 'Aucune competition en cours')
        : 'Aucune competition en cours';
    final competitionSeason = currentCompetition is Map<String, dynamic>
        ? s(currentCompetition['season'])
        : '';
    final teamRows = teams(dashboard['competition_teams']);
    final canSeePremiumAndTicket = b(
      dashboard['premium_and_ticket_stats_visible'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Bienvenue $firstname',
          subtitle: 'Vue d\'ensemble operationnelle',
          onPressed: onRefresh,
          buttonLabel: 'Rafraichir',
          icon: Icons.refresh,
          color: green,
        ),
        if (canCreateAdmin) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onCreateAdmin,
            icon: const Icon(Icons.person_add),
            label: const Text('Creer un admin'),
            style: FilledButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final compact = w < 560;
            final cardWidth = compact ? w : ((w - 10) / 2).clamp(220, 360);
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                statCard(
                  context,
                  'Admins',
                  s(dashboard['admins_count'], '0'),
                  width: cardWidth.toDouble(),
                ),
                statCard(
                  context,
                  'Users',
                  s(dashboard['users_count'], '0'),
                  width: cardWidth.toDouble(),
                ),
                statCard(
                  context,
                  'Competition en cours',
                  competitionName,
                  subtitle: competitionSeason.isEmpty
                      ? null
                      : 'Saison: $competitionSeason',
                  width: cardWidth.toDouble(),
                ),
                statCard(
                  context,
                  'Equipes participantes',
                  s(dashboard['competition_teams_count'], '0'),
                  subtitle: 'Cliquer pour voir/exporter',
                  onTap: () => showTeamsDialog(context, teamRows),
                  width: cardWidth.toDouble(),
                ),
                statCard(
                  context,
                  'Matchs prevus',
                  s(dashboard['competition_matches_planned_count'], '0'),
                  width: cardWidth.toDouble(),
                ),
                statCard(
                  context,
                  'Matchs restants',
                  s(dashboard['competition_matches_remaining_count'], '0'),
                  width: cardWidth.toDouble(),
                ),
                if (canSeePremiumAndTicket) ...[
                  statCard(
                    context,
                    'Tickets emis/vendus',
                    s(dashboard['tickets_sold'], '0'),
                    width: cardWidth.toDouble(),
                  ),
                  statCard(
                    context,
                    'Abonnements premium',
                    s(dashboard['supporter_cards_sold'], '0'),
                    width: cardWidth.toDouble(),
                  ),
                  statCard(
                    context,
                    'Paiements',
                    s(dashboard['payments_count'], '0'),
                    width: cardWidth.toDouble(),
                  ),
                  statCard(
                    context,
                    'Revenus',
                    '${s(dashboard['revenue_total'], '0')} FCFA',
                    width: cardWidth.toDouble(),
                  ),
                ],
              ],
            );
          },
        ),
        if (!canSeePremiumAndTicket)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Les donnees tickets/ventes/achats et abonnements premium sont reservees a l\'admin generale.',
              style: TextStyle(color: Color(0xFF6C8B79)),
            ),
          ),
      ],
    );
  }
}
