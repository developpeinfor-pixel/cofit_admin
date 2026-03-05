import 'package:dio/dio.dart';

class AdminHomeData {
  AdminHomeData({
    required this.dashboard,
    required this.seasons,
    required this.competitions,
    required this.teams,
    required this.groups,
    required this.matches,
    required this.news,
    required this.videos,
    required this.tickets,
    required this.standings,
    required this.standingsCompetitionId,
    required this.adminUsers,
  });

  final Map<String, dynamic> dashboard;
  final List<Map<String, dynamic>> seasons;
  final List<Map<String, dynamic>> competitions;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> news;
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> tickets;
  final List<Map<String, dynamic>> standings;
  final String? standingsCompetitionId;
  final List<Map<String, dynamic>> adminUsers;
}

class AdminHomeService {
  AdminHomeService(this._dio);

  final Dio _dio;

  List<Map<String, dynamic>> asList(dynamic data) => data is List
      ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];

  Future<Response<dynamic>> _safeGet(String path, dynamic fallbackData) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: fallbackData,
          statusCode: 200,
        );
      }
      rethrow;
    }
  }

  Future<AdminHomeData> loadAll({String? currentStandingsCompetitionId}) async {
    final rs = await Future.wait([
      _dio.get('/admin/dashboard'),
      _safeGet('/admin/seasons', <dynamic>[]),
      _dio.get('/app/competitions'),
      _dio.get('/app/teams'),
      _safeGet('/admin/groups', <dynamic>[]),
      _dio.get('/app/matches'),
      _safeGet('/admin/news', <dynamic>[]),
      _safeGet('/admin/videos', <dynamic>[]),
      _safeGet('/admin/tickets', <dynamic>[]),
      _safeGet('/admin/users/admin-accounts', <dynamic>[]),
    ]);

    final competitions = asList(rs[2].data);
    final compId =
        currentStandingsCompetitionId ?? _s(competitions.firstOrNull?['id']);
    final standings = compId.isEmpty
        ? <Map<String, dynamic>>[]
        : asList((await _dio.get('/app/standings/$compId')).data);

    return AdminHomeData(
      dashboard: Map<String, dynamic>.from(rs[0].data as Map),
      seasons: asList(rs[1].data),
      competitions: competitions,
      teams: asList(rs[3].data),
      groups: asList(rs[4].data),
      matches: asList(rs[5].data),
      news: asList(rs[6].data),
      videos: asList(rs[7].data),
      tickets: asList(rs[8].data),
      adminUsers: asList(rs[9].data),
      standings: standings,
      standingsCompetitionId: compId.isEmpty ? null : compId,
    );
  }

  String _s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
