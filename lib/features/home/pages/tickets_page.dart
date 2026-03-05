import 'package:flutter/material.dart';

import '../widgets/card_item.dart';
import '../widgets/section_header.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({
    super.key,
    required this.tickets,
    required this.qrController,
    required this.onValidate,
    required this.onRefresh,
    required this.green,
    required this.saving,
  });

  final List<Map<String, dynamic>> tickets;
  final TextEditingController qrController;
  final VoidCallback onValidate;
  final VoidCallback onRefresh;
  final Color green;
  final bool saving;

  String s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Controle Tickets',
          subtitle: 'Validation QR fonctionnelle',
          onPressed: onRefresh,
          buttonLabel: 'Rafraichir',
          icon: Icons.refresh,
          color: green,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: qrController,
                decoration: InputDecoration(
                  labelText: 'QR code ticket (scanne ou colle la valeur)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: saving ? null : onValidate,
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Valider'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tickets.take(40).map(
              (e) => CardItem(
                title:
                    '${s(e['ticket_number'], 'TICKET')} | ${s(e['status']).toUpperCase()}',
                subtitle:
                    'Date ${s(e['ticket_date'])} | Match ${s(e['match_id'], 'N/A')} | Montant ${s(e['amount'], '0')} FCFA',
              ),
            ),
      ],
    );
  }
}
