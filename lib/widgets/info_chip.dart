import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    required this.icon,
    this.color,
  });

  final String label;
  final IconData icon;

  /// 아이콘/텍스트 색상. null이면 테마 기본값 사용.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    final effectiveColor = color ?? defaultColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            color != null
                ? color!.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: effectiveColor, fontSize: 12)),
        ],
      ),
    );
  }
}
