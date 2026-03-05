import 'package:flutter/material.dart';

class AdminHomeLayout extends StatelessWidget {
  const AdminHomeLayout({
    super.key,
    required this.green,
    required this.currentTitle,
    required this.destinations,
    required this.selectedRailIndex,
    required this.saving,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onLogout,
    required this.onTabSelected,
    required this.content,
  });

  final Color green;
  final String currentTitle;
  final List<NavigationRailDestination> destinations;
  final int selectedRailIndex;
  final bool saving;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final ValueChanged<int> onTabSelected;
  final Widget content;

  String destinationLabel(NavigationRailDestination destination) {
    final label = destination.label;
    if (label is Text) {
      return label.data ?? '';
    }
    return '';
  }

  Widget bodyContent() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Erreur: $error'));
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: content,
        ),
        if (saving)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: Text('Cofit Admin | $currentTitle'),
        actions: [
          IconButton(
            onPressed: saving ? null : onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: saving ? null : onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: ListView.builder(
                  itemCount: destinations.length,
                  itemBuilder: (context, i) {
                    final d = destinations[i];
                    return ListTile(
                      leading: d.icon,
                      title: Text(destinationLabel(d)),
                      selected: i == selectedRailIndex,
                      onTap: () {
                        Navigator.pop(context);
                        onTabSelected(i);
                      },
                    );
                  },
                ),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4F7EC), Color(0xFFF7FDF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isMobile
            ? bodyContent()
            : Row(
                children: [
                  NavigationRail(
                    selectedIndex: selectedRailIndex,
                    onDestinationSelected: onTabSelected,
                    labelType: NavigationRailLabelType.all,
                    destinations: destinations,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: bodyContent()),
                ],
              ),
      ),
    );
  }
}
