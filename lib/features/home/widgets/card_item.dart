import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {
  const CardItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
    this.deleteDisabled = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
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
        trailing: (onEdit == null && onDelete == null)
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      onPressed: deleteDisabled ? null : onEdit,
                      icon: const Icon(Icons.edit, color: Color(0xFF0E5D2F)),
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: deleteDisabled ? null : onDelete,
                      icon: Icon(Icons.delete, color: Colors.red.shade700),
                    ),
                ],
              ),
      ),
    );
  }
}
