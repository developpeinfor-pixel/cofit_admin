import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/image_picker.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/file_downloader.dart';
import '../auth/login/login_screen.dart';
import 'pages/competitions_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/admins_page.dart';
import 'pages/exports_page.dart';
import 'pages/matches_page.dart';
import 'pages/news_page.dart';
import 'pages/seasons_page.dart';
import 'pages/teams_page.dart';
import 'pages/tickets_page.dart';
import 'pages/videos_page.dart';
import 'services/admin_home_service.dart';
import 'widgets/admin_home_layout.dart';

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

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> seasons = [];
  List<Map<String, dynamic>> competitions = [];
  List<Map<String, dynamic>> teams = [];
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
  bool isDateLabel(String label) => label.toLowerCase().contains('date');
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

  bool validImage(String value) =>
      value.trim().isEmpty ||
      RegExp(
        r'\.(jpg|jpeg|png)(\?.*)?$',
        caseSensitive: false,
      ).hasMatch(value.trim());
  bool validMp4(String value) =>
      RegExp(r'\.mp4(\?.*)?$', caseSensitive: false).hasMatch(value.trim());

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
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(
                controllers.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: isDateLabel(labels[i])
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
            onPressed: () => Navigator.pop(context, true),
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
    final n = TextEditingController();
    final loc = TextEditingController();
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

    final selectedSeason = ValueNotifier<String>(seasonNames.first);
    final bannerDataUrl = ValueNotifier<String>('');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter competition'),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: n,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: selectedSeason,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      initialValue: value,
                      decoration: const InputDecoration(
                        labelText: 'Saison',
                        border: OutlineInputBorder(),
                      ),
                      items: seasonNames
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (next) {
                        if (next != null) {
                          selectedSeason.value = next;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: loc,
                  decoration: const InputDecoration(
                    labelText: 'Lieu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: bannerDataUrl,
                  builder: (context, value, child) {
                    final hasImage = value.isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final image = await pickImageAsDataUrl();
                            if (image != null && image.isNotEmpty) {
                              bannerDataUrl.value = image;
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            hasImage
                                ? 'Banniere selectionnee (changer)'
                                : 'Uploader banniere (jpg/jpeg/png)',
                          ),
                        ),
                        if (hasImage) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              value,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
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

    if (ok == true) {
      await run(
        () => api.dio.post(
          '/admin/competitions',
          data: {
            'name': n.text.trim(),
            'season': selectedSeason.value,
            'location': loc.text.trim(),
            'banner_url': bannerDataUrl.value.isEmpty
                ? null
                : bannerDataUrl.value,
          },
        ),
        'Competition ajoutee',
      );
    }
  }

  Future<void> addTeam() async {
    final n = TextEditingController();
    final logo = TextEditingController();
    final players = TextEditingController();
    final staff = TextEditingController();
    await openSimpleForm(
      title: 'Ajouter equipe',
      controllers: [n, logo, players, staff],
      labels: [
        'Nom equipe',
        'Logo URL (jpg/jpeg/png)',
        'Joueurs JSON',
        'Staff JSON',
      ],
      onSave: () async {
        if (!validImage(logo.text)) return;
        final p = players.text.trim().isEmpty ? null : jsonDecode(players.text);
        final st = staff.text.trim().isEmpty ? null : jsonDecode(staff.text);
        await run(
          () => api.dio.post(
            '/admin/teams',
            data: {
              'name': n.text.trim(),
              'logo_url': logo.text.trim(),
              'players': p,
              'staff': st,
            },
          ),
          'Equipe ajoutee',
        );
      },
    );
  }

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

  Future<void> addNews() async {
    final t = TextEditingController();
    final c = TextEditingController();
    final i = TextEditingController();
    await openSimpleForm(
      title: 'Ajouter actualite',
      controllers: [t, c, i],
      labels: ['Titre', 'Contenu', 'Image URL (jpg/jpeg/png)'],
      onSave: () => validImage(i.text)
          ? run(
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
            )
          : Future.value(),
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
      onSave: () {
        final size = int.tryParse(sz.text.trim());
        if (!validMp4(u.text) || (size != null && size > 500)) {
          return Future.value();
        }
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
    final f = TextEditingController();
    final l = TextEditingController();
    final e = TextEditingController();
    final p = TextEditingController();
    final pwd = TextEditingController();
    final selectedRole = ValueNotifier<String>(roleSenior);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau compte admin'),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: f,
                  decoration: const InputDecoration(
                    labelText: 'Prenom',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: l,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: e,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: p,
                  decoration: const InputDecoration(
                    labelText: 'Telephone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pwd,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: selectedRole,
                  builder: (context, value, child) {
                    return DropdownButtonFormField<String>(
                      initialValue: value,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: roleGeneral,
                          child: Text('Admin generale'),
                        ),
                        DropdownMenuItem(
                          value: roleSenior,
                          child: Text('Admin seniors'),
                        ),
                        DropdownMenuItem(
                          value: roleJunior,
                          child: Text('Admin juniors'),
                        ),
                      ],
                      onChanged: (next) {
                        if (next != null) {
                          selectedRole.value = next;
                        }
                      },
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
            child: const Text('Creer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await run(
        () => api.dio.post(
          '/admin/auth/create-account',
          data: {
            'first_name': f.text.trim(),
            'last_name': l.text.trim(),
            'email': e.text.trim(),
            'phone': p.text.trim(),
            'password': pwd.text,
            'role': selectedRole.value,
          },
        ),
        'Compte admin cree',
      );
    }
  }

  List<int> visibleTabs() {
    if (role == roleGeneral) {
      return const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    }
    if (role == roleSenior) {
      return const [0, 1, 2, 3, 4, 5, 6];
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
            () => api.dio.delete('/admin/competitions/${s(e['id'])}'),
            'Competition supprimee',
          ),
          green: green,
          saving: saving,
        );
      case 3:
        return TeamsPage(
          teams: teams,
          onAdd: addTeam,
          onDelete: (e) => run(
            () => api.dio.delete('/admin/teams/${s(e['id'])}'),
            'Equipe supprimee',
          ),
          green: green,
          saving: saving,
        );
      case 4:
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
      case 5:
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
      case 6:
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
      case 7:
        return TicketsPage(
          tickets: tickets,
          qrController: qrValidateController,
          onValidate: validateTicketQr,
          onRefresh: load,
          green: green,
          saving: saving,
        );
      default:
        if (tab == 8) {
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
    return AdminHomeLayout(
      green: green,
      currentTitle: labels[currentTab],
      destinations: railDestinations,
      selectedRailIndex: safeSelectedRailIndex,
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
