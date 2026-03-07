import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cofit_admin/features/home/models/dashboard_stats.dart';
import 'package:cofit_admin/features/home/pages/dashboard_page.dart';
import 'package:cofit_admin/features/home/widgets/admin_home_layout.dart';

void main() {
  testWidgets('AdminHomeLayout shows drawer on mobile and handles tab selection', (
    WidgetTester tester,
  ) async {
    var selectedIndex = -1;
    final destinations = const [
      NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
      NavigationRailDestination(icon: Icon(Icons.groups), label: Text('Equipes')),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(820, 700)),
          child: AdminHomeLayout(
            green: const Color(0xFF0E5D2F),
            currentTitle: 'Dashboard',
            destinations: destinations,
            selectedRailIndex: 0,
            saving: false,
            loading: false,
            error: null,
            onRefresh: () {},
            onLogout: () {},
            onTabSelected: (i) => selectedIndex = i,
            content: const Text('Contenu'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    await tester.tap(find.text('Equipes'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
  });

  testWidgets('AdminHomeLayout shows navigation rail on desktop', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: AdminHomeLayout(
            green: const Color(0xFF0E5D2F),
            currentTitle: 'Dashboard',
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
            ],
            selectedRailIndex: 0,
            saving: false,
            loading: false,
            error: null,
            onRefresh: () {},
            onLogout: () {},
            onTabSelected: (_) {},
            content: const Text('Contenu'),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('DashboardPage renders admin creation action when allowed', (
    WidgetTester tester,
  ) async {
    var createAdminPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardPage(
              dashboard: DashboardStats.fromJson(const {
                'current_admin_first_name': 'Alice',
                'admins_count': 2,
                'users_count': 10,
                'competition_teams_count': 4,
                'competition_matches_planned_count': 6,
                'competition_matches_remaining_count': 3,
                'premium_and_ticket_stats_visible': true,
                'tickets_sold': 15,
                'supporter_cards_sold': 5,
                'payments_count': 20,
                'revenue_total': 30000,
                'current_competition': {'name': 'Cofit Cup', 'season': '2026'},
                'competition_teams': [],
              }),
              onRefresh: () {},
              green: const Color(0xFF0E5D2F),
              canCreateAdmin: true,
              onCreateAdmin: () => createAdminPressed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Creer un admin'), findsOneWidget);
    await tester.tap(find.text('Creer un admin'));
    await tester.pump();
    expect(createAdminPressed, isTrue);
  });
}
