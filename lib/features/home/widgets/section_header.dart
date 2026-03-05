import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.buttonLabel,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final String buttonLabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        Text(subtitle, style: const TextStyle(color: Color(0xFF3F7657))),
        const SizedBox(height: 8),
        Align(
          alignment: isCompact ? Alignment.centerLeft : Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            icon: Icon(icon),
            label: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}
