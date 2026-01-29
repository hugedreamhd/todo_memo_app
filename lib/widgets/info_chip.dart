import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
