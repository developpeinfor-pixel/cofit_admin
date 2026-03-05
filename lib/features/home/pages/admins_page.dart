import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class AdminsPage extends StatelessWidget {
  const AdminsPage({
    super.key,
    required this.admins,
    required this.onAdd,
    required this.green,
  });

  final List<Map<String, dynamic>> admins;
  final VoidCallback onAdd;
  final Color green;

  String s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

  String roleLabel(String role) {
    switch (role) {
      case 'admin_general':
        return 'Admin generale';
      case 'admin_senior':
        return 'Admin seniors';
      case 'admin_junior':
        return 'Admin juniors';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Comptes Admin',
          subtitle: 'Creation reservee aux admins generales',
          onPressed: onAdd,
          buttonLabel: 'Ajouter',
          icon: Icons.person_add,
          color: green,
        ),
        const SizedBox(height: 8),
        ...admins.map(
          (e) => CardItem(
            title: '${s(e['first_name'])} ${s(e['last_name'])}',
            subtitle: '${s(e['email'])} | ${s(e['phone'])} | ${roleLabel(s(e['role']))}',
          ),
        ),
      ],
    );
  }
}
