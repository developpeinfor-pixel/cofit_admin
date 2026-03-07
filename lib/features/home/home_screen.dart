import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/file_downloader.dart';
import '../auth/login/login_screen.dart';
import 'models/competition_model.dart';
import 'models/dashboard_stats.dart';
import 'pages/competitions_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/admins_page.dart';
import 'pages/exports_page.dart';
import 'pages/groups_page.dart';
import 'pages/matches_page.dart';
import 'pages/news_page.dart';
import 'pages/seasons_page.dart';
import 'pages/teams_page.dart';
import 'pages/tickets_page.dart';
import 'pages/videos_page.dart';
import 'services/admin_home_service.dart';
import 'utils/home_validators.dart';
import 'widgets/admin_home_layout.dart';
import 'widgets/dialogs/admin_account_form_dialog.dart';
import 'widgets/dialogs/competition_form_dialog.dart';
import 'widgets/dialogs/team_form_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const green = Color(0xFF0E5D2F);
  static const roleGeneral = 'admin_general';
  static const roleSenior = 'admin_senior';
  static const roleJunior = 'admin_junior';

  final api = ApiClient();
  late final homeService = AdminHomeService(api.dio);
  final storage = SecureStorage();
  final qrValidateController = TextEditingController();

  bool loading = true;
  bool saving = false;
  String? error;
  String role = '';
  int tab = 0;

  DashboardStats dashboard = DashboardStats.empty();
  List<Map<String, dynamic>> seasons = [];
  List<CompetitionModel> competitions = [];
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> matches = [];
  List<Map<String, dynamic>> news = [];
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> tickets = [];
  List<Map<String, dynamic>> standings = [];
  List<Map<String, dynamic>> adminUsers = [];
  String? standingsCompetitionId;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    qrValidateController.dispose();
    super.dispose();
  }

  String s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;
  String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  DateTime? parseIsoDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> pickDate(TextEditingController controller) async {
    final parsed = parseIsoDate(controller.text);
    final now = DateTime.now();
    final initial = parsed ?? now;

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF1D1D1D),
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              headerBackgroundColor: green,
              headerForegroundColor: Colors.white,
              todayBorder: const BorderSide(
                color: Color(0xFF0E5D2F),
                width: 1.2,
              ),
              dayShape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      controller.text = formatDate(selected);
    }
  }

  double dialogWidth(double preferred) {
    final max = MediaQuery.of(context).size.width * 0.92;
    return max < preferred ? max : preferred;
  }

  Set<String> groupTeamIds(Map<String, dynamic> group) {
    final ids = <String>{};

    final directIds = group['team_ids'];
    if (directIds is List) {
      for (final raw in directIds) {
        final id = s(raw);
        if (id.isNotEmpty) ids.add(id);
      }
    }

    final rows = group['teams'];
    if (rows is List) {
      for (final raw in rows) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final teamId = s(row['team_id']);
        if (teamId.isNotEmpty) ids.add(teamId);

        final team = row['team'];
        if (team is Map) {
          final nestedId = s(team['id']);
          if (nestedId.isNotEmpty) ids.add(nestedId);
        }
      }
    }

    return ids;
  }

  Set<String> assignedTeamIds() {
    final ids = <String>{};
    for (final group in groups) {
      ids.addAll(groupTeamIds(group));
    }
    return ids;
  }

  String normalizeHeader(String value) => value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('ù', 'u')
      .split('')
      .where((ch) {
        final code = ch.codeUnitAt(0);
        final isDigit = code >= 48 && code <= 57;
        final isLower = code >= 97 && code <= 122;
        return isDigit || isLower;
      })
      .join();

  List<String> splitByDelimiters(String input, Set<int> delimiters) {
    final parts = <String>[];
    var start = 0;
    for (var i = 0; i < input.length; i++) {
      if (delimiters.contains(input.codeUnitAt(i))) {
        parts.add(input.substring(start, i));
        start = i + 1;
      }
    }
    parts.add(input.substring(start));
    return parts;
  }

  String playersToLines(dynamic value) {
    if (value is! List) return '';
    return value
        .map((e) {
          if (e is! Map) return '';
          final nom = s(e['nom']);
          final prenoms = s(e['prenoms'], s(e['prenom']));
          final surnom = s(e['surnom'], s(e['surnom']));
          final dossard = s(e['dossard'], s(e['dossart'], s(e['dorsal'])));
          return '$nom;$prenoms;$surnom;$dossard';
        })
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }

  String staffToLines(dynamic value) {
    if (value is! List) return '';
    return value
        .map((e) {
          if (e is! Map) return '';
          final nom = s(e['nom']);
          final prenom = s(e['prenom'], s(e['prenoms']));
          final poste = s(e['poste']);
          return '$nom;$prenom;$poste';
        })
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }

  List<Map<String, dynamic>> parsePlayersLines(String raw) {
    final out = <Map<String, dynamic>>[];
    for (final line in raw.split('\n')) {
      final cleaned = line.trim();
      if (cleaned.isEmpty) continue;
      final parts = splitByDelimiters(cleaned, {59, 44, 9, 124})
          .map((e) => e.trim())
          .toList();
      out.add({
        'nom': parts.isNotEmpty ? parts[0] : '',
        'prenoms': parts.length > 1 ? parts[1] : '',
        'surnom': parts.length > 2 ? parts[2] : '',
        'dossard': parts.length > 3 ? parts[3] : '',
      });
    }
    return out;
  }

  List<Map<String, dynamic>> parseStaffLines(String raw) {
    final out = <Map<String, dynamic>>[];
    for (final line in raw.split('\n')) {
      final cleaned = line.trim();
      if (cleaned.isEmpty) continue;
      final parts = splitByDelimiters(cleaned, {59, 44, 9, 124})
          .map((e) => e.trim())
          .toList();
      out.add({
        'nom': parts.isNotEmpty ? parts[0] : '',
        'prenom': parts.length > 1 ? parts[1] : '',
        'poste': parts.length > 2 ? parts[2] : '',
      });
    }
    return out;
  }

  List<List<String>> parseTabularBytes(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) {
      final text = utf8.decode(bytes, allowMalformed: true);
      final lines = const LineSplitter().convert(text).where(
        (l) => l.trim().isNotEmpty,
      );
      return lines
          .map(
            (l) => splitByDelimiters(l, {59, 44, 9})
                .map((e) => e.trim())
                .toList(),
          )
          .toList();
    }
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];
    final table = excel.tables.values.first;
    return table.rows
        .map((r) => r.map((c) => c?.value?.toString().trim() ?? '').toList())
        .where((r) => r.any((c) => c.isNotEmpty))
        .toList();
  }

  Future<List<Map<String, dynamic>>?> importPlayersFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final rows = parseTabularBytes(bytes, file.name);
    if (rows.isEmpty) return [];
    final header = rows.first.map(normalizeHeader).toList();
    int idx(String key) => header.indexOf(key);
    final nomIdx = idx('nom');
    final prenomsIdx = idx('prenoms') >= 0 ? idx('prenoms') : idx('prenom');
    final surnomIdx = idx('surnom');
    final dossardIdx = idx('dossard') >= 0 ? idx('dossard') : idx('dorsard');

    final dataRows = rows.skip(1);
    final out = <Map<String, dynamic>>[];
    for (final r in dataRows) {
      final nom = nomIdx >= 0 && nomIdx < r.length ? r[nomIdx] : '';
      final prenoms = prenomsIdx >= 0 && prenomsIdx < r.length
          ? r[prenomsIdx]
          : '';
      final surnom = surnomIdx >= 0 && surnomIdx < r.length ? r[surnomIdx] : '';
      final dossard = dossardIdx >= 0 && dossardIdx < r.length
          ? r[dossardIdx]
          : '';
      if ([nom, prenoms, surnom, dossard].every((v) => v.trim().isEmpty)) {
        continue;
      }
      out.add({
        'nom': nom,
        'prenoms': prenoms,
        'surnom': surnom,
        'dossard': dossard,
      });
    }
    return out;
  }

  Future<List<Map<String, dynamic>>?> importStaffFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final rows = parseTabularBytes(bytes, file.name);
    if (rows.isEmpty) return [];
    final header = rows.first.map(normalizeHeader).toList();
    int idx(String key) => header.indexOf(key);
    final nomIdx = idx('nom');
    final prenomIdx = idx('prenom') >= 0 ? idx('prenom') : idx('prenoms');
    final posteIdx = idx('poste');

    final dataRows = rows.skip(1);
    final out = <Map<String, dynamic>>[];
    for (final r in dataRows) {
      final nom = nomIdx >= 0 && nomIdx < r.length ? r[nomIdx] : '';
      final prenom = prenomIdx >= 0 && prenomIdx < r.length ? r[prenomIdx] : '';
      final poste = posteIdx >= 0 && posteIdx < r.length ? r[posteIdx] : '';
      if ([nom, prenom, poste].every((v) => v.trim().isEmpty)) continue;
      out.add({'nom': nom, 'prenom': prenom, 'poste': poste});
    }
    return out;
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (role.isEmpty) {
        role = await resolveRole();
      }
      final data = await homeService.loadAll(
        currentStandingsCompetitionId: standingsCompetitionId,
      );
      if (!mounted) return;
      final tabs = visibleTabs();
      if (!tabs.contains(tab)) {
        tab = tabs.first;
      }
      setState(() {
        dashboard = data.dashboard;
        seasons = data.seasons;
        competitions = data.competitions;
        teams = data.teams;
        groups = data.groups;
        matches = data.matches;
        news = data.news;
        videos = data.videos;
        tickets = data.tickets;
        adminUsers = data.adminUsers;
        standingsCompetitionId = data.standingsCompetitionId;
        standings = data.standings;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> run(Future<void> Function() action, String success) async {
    setState(() => saving = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
      await load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.response?.data ?? e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> openSimpleForm({
    required String title,
    required List<TextEditingController> controllers,
    required List<String> labels,
    required Future<void> Function() onSave,
    String? Function()? validateBeforeSave,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: dialogWidth(560),
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(
                controllers.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HomeValidators.isDateLabel(labels[i])
                      ? TextField(
                          controller: controllers[i],
                          readOnly: true,
                          onTap: () => pickDate(controllers[i]),
                          decoration: InputDecoration(
                            labelText: labels[i],
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: const Icon(Icons.calendar_month),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : TextField(
                          controller: controllers[i],
                          maxLines: labels[i].contains('JSON') ? 4 : 1,
                          decoration: InputDecoration(
                            labelText: labels[i],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final validationError = validateBeforeSave?.call();
              if (validationError != null && validationError.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(validationError)),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok == true) await onSave();
  }

  Future<void> exportFile(String ext) async {
    await run(() async {
      final res = await api.dio.get<List<int>>(
        '/admin/exports/stats.$ext',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? []);
      final path = await downloadBytes(
        fileName: 'cofit-stats-${DateTime.now().millisecondsSinceEpoch}.$ext',
        mimeType: ext == 'pdf' ? 'application/pdf' : 'text/csv',
        bytes: bytes,
      );
      if (path != null && path.isNotEmpty && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fichier: $path')));
      }
    }, 'Export $ext termine');
  }

  Future<void> logout() async {
    await storage.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> addSeason() async {
    final n = TextEditingController();
    final d1 = TextEditingController();
    final d2 = TextEditingController();
    await openSimpleForm(
      title: 'Ajouter saison',
      controllers: [n, d1, d2],
      labels: ['Nom', 'Date debut YYYY-MM-DD', 'Date fin YYYY-MM-DD'],
      onSave: () => run(
        () => api.dio.post(
          '/admin/seasons',
          data: {
            'name': n.text.trim(),
            'start_date': d1.text.trim(),
            'end_date': d2.text.trim(),
          },
        ),
        'Saison ajoutee',
      ),
    );
  }

  Future<void> addCompetition() async {
    final seasonNames =
        seasons
            .map((e) => s(e['name']).trim())
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (seasonNames.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune saison disponible. Cree d abord une saison.'),
        ),
      );
      return;
    }

    final form = await showCompetitionFormDialog(
      context: context,
      seasonNames: seasonNames,
      width: dialogWidth(580),
    );

    if (form == null) return;

    await run(
      () => api.dio.post(
        '/admin/competitions',
        data: {
          'name': form.name,
          'season': form.season,
          'location': form.location,
          'banner_url': form.bannerUrl,
        },
      ),
      'Competition ajoutee',
    );
  }

  Future<void> openTeamForm({Map<String, dynamic>? team}) async {
    final isEdit = team != null;
    final form = await showTeamFormDialog(
      context: context,
      isEdit: isEdit,
      initialName: s(team?['name']),
      initialClubColors: s(team?['club_colors']),
      initialPlayersLines: playersToLines(team?['players']),
      initialStaffLines: staffToLines(team?['staff']),
      initialLogoUrl: s(team?['logo_url']),
      width: dialogWidth(680),
      onImportPlayers: importPlayersFromFile,
      onImportStaff: importStaffFromFile,
      stringify: s,
    );

    if (form == null) return;

    if (!HomeValidators.hasAtLeastTwoColors(form.clubColors)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute au moins 2 couleurs pour le club.'),
        ),
      );
      return;
    }

    final players = parsePlayersLines(form.playersLines);
    final staff = parseStaffLines(form.staffLines);
    if (players.length > 20) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 20 joueurs autorises.')),
      );
      return;
    }
    if (staff.length > 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 membres staff autorises.')),
      );
      return;
    }

    final payload = {
      'name': form.name,
      'club_colors': form.clubColors,
      'logo_url': form.logoUrl,
      'players': players,
      'staff': staff,
    };

    final teamId = s(team?['id']);
    await run(
      () => isEdit
          ? api.dio.patch('/admin/teams/$teamId', data: payload)
          : api.dio.post('/admin/teams', data: payload),
      isEdit ? 'Equipe mise a jour' : 'Equipe ajoutee',
    );
  }

  Future<void> addTeam() => openTeamForm();

  Future<void> editTeam(Map<String, dynamic> team) => openTeamForm(team: team);

  Future<void> addMatch() async {
    final home = TextEditingController();
    final away = TextEditingController();
    final date = TextEditingController();
    final stats = TextEditingController();
    await openSimpleForm(
      title: 'Ajouter match',
      controllers: [home, away, date, stats],
      labels: [
        'ID Equipe domicile',
        'ID Equipe exterieur',
        'Date YYYY-MM-DD',
        'Stats JSON',
      ],
      onSave: () async {
        final parsed = stats.text.trim().isEmpty
            ? null
            : jsonDecode(stats.text);
        await run(
          () => api.dio.post(
            '/admin/matches',
            data: {
              'home_team_id': home.text.trim(),
              'away_team_id': away.text.trim(),
              'match_date': date.text.trim(),
              'kickoff_time': '16:00:00',
              'stadium': 'A definir',
              'ticket_price': '0',
              'status': 'upcoming',
              'match_stats': parsed,
            },
          ),
          'Match ajoute',
        );
      },
    );
  }

  Future<void> addGroup() async {
    if (competitions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucune competition disponible. Cree une competition d abord.',
          ),
        ),
      );
      return;
    }
    if (teams.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune equipe disponible. Cree les equipes d abord.'),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final teamCountController = TextEditingController();
    final selectedCompetition = ValueNotifier<String?>(competitions.first.id);
    final phase = ValueNotifier<String>('group_stage');
    final selectedTeams = ValueNotifier<Set<String>>(<String>{});
    final teamIdsInGroup = assignedTeamIds();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter groupe'),
        content: SizedBox(
          width: dialogWidth(620),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: selectedCompetition,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      initialValue: value,
                      decoration: const InputDecoration(
                        labelText: 'Competition',
                        border: OutlineInputBorder(),
                      ),
                      items: competitions
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.name} (${c.season})'),
                            ),
                          )
                          .toList(),
                      onChanged: (next) {
                        if (next == null) return;
                        selectedCompetition.value = next;
                        selectedTeams.value = selectedTeams.value
                            .where((id) => !teamIdsInGroup.contains(id))
                            .toSet();
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe (ex: Groupe A)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: phase,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      initialValue: value,
                      decoration: const InputDecoration(
                        labelText: 'Phase',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'group_stage',
                          child: Text('Phase de poules'),
                        ),
                      ],
                      onChanged: (next) {
                        if (next != null) phase.value = next;
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final availableCount = teams
                        .where((team) => !teamIdsInGroup.contains(s(team['id'])))
                        .length;
                    return TextField(
                      controller: teamCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nombre d equipes dans le groupe',
                        helperText: 'Maximum $availableCount equipes disponibles',
                        border: const OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selection des equipes',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: selectedTeams,
                  builder: (context, selected, child) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: teams.map((team) {
                        final id = s(team['id']);
                        final isSelected = selected.contains(id);
                        final isAssigned = teamIdsInGroup.contains(id);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            isAssigned
                                ? '${s(team['name'], 'Equipe')} (deja dans un groupe)'
                                : s(team['name'], 'Equipe'),
                          ),
                          onSelected: isAssigned
                              ? null
                              : (checked) {
                                  final next = Set<String>.from(selected);
                                  if (checked) {
                                    next.add(id);
                                  } else {
                                    next.remove(id);
                                  }
                                  selectedTeams.value = next;
                                },
                        );
                      }).toList(),
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    final availableCount = teams
                        .where((team) => !teamIdsInGroup.contains(s(team['id'])))
                        .length;
                    if (availableCount == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Toutes les equipes sont deja affectees a un groupe.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '$availableCount equipe(s) disponible(s).',
                        style: const TextStyle(color: Color(0xFF5F6368)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok != true || selectedCompetition.value == null) return;

    final expectedCount = int.tryParse(teamCountController.text.trim());
    if (nameController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du groupe est obligatoire.')),
      );
      return;
    }
    if (expectedCount == null || expectedCount < 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nombre d equipes doit etre superieur a 0.'),
        ),
      );
      return;
    }

    final availableCount = teams
        .where((team) => !teamIdsInGroup.contains(s(team['id'])))
        .length;
    if (expectedCount > availableCount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le nombre d equipes ne peut pas depasser $availableCount equipe(s) disponible(s).',
          ),
        ),
      );
      return;
    }

    final selectedIds = selectedTeams.value.toList();
    final conflictingIds = selectedIds
        .where((id) => teamIdsInGroup.contains(id))
        .toList();
    if (conflictingIds.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une equipe ne peut appartenir qu a un seul groupe.'),
        ),
      );
      return;
    }

    if (selectedIds.length != expectedCount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selectionne exactement $expectedCount equipes pour ce groupe.',
          ),
        ),
      );
      return;
    }

    await run(
      () => api.dio.post(
        '/admin/groups',
        data: {
          'competition_id': selectedCompetition.value,
          'name': nameController.text.trim(),
          'phase': phase.value,
          'team_count': expectedCount,
          'team_ids': selectedIds,
        },
      ),
      'Groupe ajoute',
    );
  }

  Future<void> addNews() async {
    final t = TextEditingController();
    final c = TextEditingController();
    final i = TextEditingController();
    await openSimpleForm(
      title: 'Ajouter actualite',
      controllers: [t, c, i],
      labels: ['Titre', 'Contenu', 'Image URL (jpg/jpeg/png)'],
      validateBeforeSave: () {
        if (t.text.trim().isEmpty) {
          return 'Le titre est obligatoire.';
        }
        if (c.text.trim().isEmpty) {
          return 'Le contenu est obligatoire.';
        }
        if (!HomeValidators.validImage(i.text)) {
          return 'Image invalide. Utilise un lien JPG/JPEG/PNG.';
        }
        return null;
      },
      onSave: () => run(
        () => api.dio.post(
          '/admin/news',
          data: {
            'title': t.text.trim(),
            'content': c.text.trim(),
            'image_url': i.text.trim(),
            'is_published': true,
          },
        ),
        'Actualite ajoutee',
      ),
    );
  }

  Future<void> addVideo() async {
    final t = TextEditingController();
    final u = TextEditingController();
    final ty = TextEditingController(text: 'interview');
    final sz = TextEditingController();
    await openSimpleForm(
      title: 'Ajouter video',
      controllers: [t, u, ty, sz],
      labels: [
        'Titre',
        'URL MP4',
        'Type: summary/highlight/gallery/interview',
        'Taille MB (<=500)',
      ],
      validateBeforeSave: () {
        if (t.text.trim().isEmpty) {
          return 'Le titre est obligatoire.';
        }
        if (!HomeValidators.validMp4(u.text)) {
          return 'URL video invalide. Le lien doit finir par .mp4';
        }
        final sizeText = sz.text.trim();
        if (sizeText.isNotEmpty) {
          final size = int.tryParse(sizeText);
          if (size == null || size < 0) {
            return 'La taille MB doit etre un nombre positif.';
          }
          if (size > 500) {
            return 'La taille video ne doit pas depasser 500 MB.';
          }
        }
        return null;
      },
      onSave: () {
        final sizeText = sz.text.trim();
        final size = sizeText.isEmpty ? null : int.tryParse(sizeText);
        return run(
          () => api.dio.post(
            '/admin/videos',
            data: {
              'title': t.text.trim(),
              'video_url': u.text.trim(),
              'type': ty.text.trim(),
              'video_size_mb': size,
              'is_published': true,
            },
          ),
          'Video ajoutee',
        );
      },
    );
  }

  Future<void> validateTicketQr() async {
    await run(
      () => api.dio.post(
        '/admin/tickets/validate',
        data: {'qr_code': qrValidateController.text.trim()},
      ),
      'Ticket valide',
    );
  }

  Future<void> createAdminAccount() async {
    final form = await showAdminAccountFormDialog(
      context: context,
      roleGeneral: roleGeneral,
      roleSenior: roleSenior,
      roleJunior: roleJunior,
      initialRole: roleSenior,
      width: dialogWidth(580),
    );
    if (form == null) return;

    await run(
      () => api.dio.post(
        '/admin/auth/create-account',
        data: {
          'first_name': form.firstName,
          'last_name': form.lastName,
          'email': form.email,
          'phone': form.phone,
          'password': form.password,
          'role': form.role,
        },
      ),
      'Compte admin cree',
    );
  }

  List<int> visibleTabs() {
    if (role == roleGeneral) {
      return const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    }
    if (role == roleSenior) {
      return const [0, 1, 2, 3, 4, 5, 6, 7];
    }
    return const [0];
  }

  Future<String> resolveRole() async {
    final storedRole = await storage.getRole();
    if (storedRole != null && storedRole.isNotEmpty) {
      return storedRole;
    }

    final token = await storage.getToken();
    if (token == null || token.isEmpty) {
      return '';
    }

    try {
      final parts = token.split('.');
      if (parts.length < 2) return '';
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final parsedRole = payload is Map<String, dynamic>
          ? payload['role']
          : null;
      if (parsedRole is String && parsedRole.isNotEmpty) {
        await storage.saveRole(parsedRole);
        return parsedRole;
      }
    } catch (_) {}
    return '';
  }

  Widget content() {
    switch (tab) {
      case 0:
        return DashboardPage(
          dashboard: dashboard,
          onRefresh: load,
          green: green,
          canCreateAdmin: role == roleGeneral,
          onCreateAdmin: createAdminAccount,
        );
      case 1:
        return SeasonsPage(
          seasons: seasons,
          onAdd: addSeason,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/seasons/${s(e['id'])}'),
            'Saison supprimee',
          ),
          green: green,
          saving: saving,
        );
      case 2:
        return CompetitionsPage(
          competitions: competitions,
          onAdd: addCompetition,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/competitions/${e.id}'),
            'Competition supprimee',
          ),
          green: green,
          saving: saving,
        );
      case 3:
        return TeamsPage(
          teams: teams,
          onAdd: addTeam,
          onEdit: editTeam,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/teams/${s(e['id'])}'),
            'Equipe supprimee',
          ),
          green: green,
          saving: saving,
        );
      case 4:
        return GroupsPage(
          groups: groups,
          onAdd: addGroup,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/groups/${s(e['id'])}'),
            'Groupe supprime',
          ),
          green: green,
          saving: saving,
        );
      case 5:
        return MatchesPage(
          matches: matches,
          onAdd: addMatch,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/matches/${s(e['id'])}'),
            'Match supprime',
          ),
          green: green,
          saving: saving,
        );
      case 6:
        return NewsPage(
          news: news,
          onAdd: addNews,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/news/${s(e['id'])}'),
            'Actualite supprimee',
          ),
          green: green,
          saving: saving,
        );
      case 7:
        return VideosPage(
          videos: videos,
          onAdd: addVideo,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/videos/${s(e['id'])}'),
            'Video supprimee',
          ),
          green: green,
          saving: saving,
        );
      case 8:
        return TicketsPage(
          tickets: tickets,
          qrController: qrValidateController,
          onValidate: validateTicketQr,
          onRefresh: load,
          green: green,
          saving: saving,
        );
      default:
        if (tab == 9) {
          return ExportsPage(
            onExportCsv: () => exportFile('csv'),
            onExportPdf: () => exportFile('pdf'),
            standings: standings,
            green: green,
            saving: saving,
          );
        }
        return AdminsPage(
          admins: adminUsers,
          onAdd: createAdminAccount,
          green: green,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Dashboard',
      'Saisons',
      'Competitions',
      'Equipes',
      'Groupes',
      'Matchs',
      'Actus',
      'Videos',
      'Tickets',
      'Exports',
      'Comptes',
    ];
    const icons = [
      Icons.dashboard,
      Icons.calendar_month,
      Icons.emoji_events,
      Icons.groups,
      Icons.view_module,
      Icons.sports_soccer,
      Icons.newspaper,
      Icons.movie,
      Icons.qr_code_2,
      Icons.download,
      Icons.admin_panel_settings,
    ];
    final tabs = visibleTabs();
    final selectedRailIndex = tabs.indexOf(tab);
    final safeSelectedRailIndex = selectedRailIndex < 0 ? 0 : selectedRailIndex;
    final railDestinations = tabs
        .map(
          (idx) => NavigationRailDestination(
            icon: Icon(icons[idx]),
            label: Text(labels[idx]),
          ),
        )
        .toList();
    final currentTab = tabs[safeSelectedRailIndex];
    const lazyTabs = {1, 2, 3, 5, 6, 7, 10};
    return AdminHomeLayout(
      green: green,
      currentTitle: labels[currentTab],
      destinations: railDestinations,
      selectedRailIndex: safeSelectedRailIndex,
      useOuterScroll: !lazyTabs.contains(currentTab),
      saving: saving,
      loading: loading,
      error: error,
      onRefresh: load,
      onLogout: logout,
      onTabSelected: (i) => setState(() => tab = tabs[i]),
      content: content(),
    );
  }
}

