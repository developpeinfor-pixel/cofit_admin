import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {
  const CardItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.onDelete,
    this.deleteDisabled = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onDelete;
  final bool deleteDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7ECD9)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: onDelete == null
            ? null
            : IconButton(
                onPressed: deleteDisabled ? null : onDelete,
                icon: Icon(Icons.delete, color: Colors.red.shade700),
              ),
      ),
    );
  }
}
