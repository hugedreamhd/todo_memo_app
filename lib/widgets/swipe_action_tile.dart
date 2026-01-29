import 'package:flutter/material.dart';

class SwipeActionTile extends StatefulWidget {
  const SwipeActionTile({
    super.key,
    required this.child,
    required this.onSave,
    required this.onDelete,
    required this.saveColor,
    required this.deleteColor,
    required this.saveLabel,
    required this.deleteLabel,
    required this.saveIcon,
    required this.deleteIcon,
    required this.childBorderRadius,
    required this.isHighlighted,
    this.maxSlideFactor = 0.33,
  });

  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final Color saveColor;
  final Color deleteColor;
  final String saveLabel;
  final String deleteLabel;
  final IconData saveIcon;
  final IconData deleteIcon;
  final BorderRadius childBorderRadius;
  final bool isHighlighted;
  final double maxSlideFactor;

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;
  double _offsetX = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      if (_animation == null) return;
      setState(() {
        _offsetX = _animation!.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _controller.stop();
    _animation = Tween<double>(
      begin: _offsetX,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSlide = constraints.maxWidth * widget.maxSlideFactor;
        final dragProgress = (-_offsetX / maxSlide).clamp(0.0, 1.0);

        final easedProgress = Curves.linear.transform(dragProgress);

        final childRadius = BorderRadius.only(
          topLeft: widget.childBorderRadius.topLeft,
          bottomLeft: widget.childBorderRadius.bottomLeft,
          topRight:
              Radius.lerp(
                widget.childBorderRadius.topRight,
                Radius.zero,
                easedProgress,
              )!,
          bottomRight:
              Radius.lerp(
                widget.childBorderRadius.bottomRight,
                Radius.zero,
                easedProgress,
              )!,
        );

        final backgroundRadius = BorderRadius.only(
          topRight: widget.childBorderRadius.topRight,
          bottomRight: widget.childBorderRadius.bottomRight,
          topLeft: Radius.zero,
          bottomLeft: Radius.zero,
        );

        final borderColor =
            widget.isHighlighted
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            _controller.stop();
            final nextOffset = (_offsetX + details.delta.dx).clamp(
              -maxSlide,
              0.0,
            );
            if (nextOffset != _offsetX) {
              setState(() {
                _offsetX = nextOffset;
              });
            }
          },
          onHorizontalDragEnd: (_) {
            final shouldOpen = _offsetX.abs() >= maxSlide * 0.4;
            _animateTo(shouldOpen ? -maxSlide : 0.0);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: backgroundRadius,
                    child: Container(
                      width: maxSlide,
                      foregroundDecoration: BoxDecoration(
                        borderRadius: backgroundRadius,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: widget.deleteColor,
                        borderRadius: backgroundRadius,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SwipeActionButton(
                              color: widget.saveColor,
                              icon: widget.saveIcon,
                              label: widget.saveLabel,
                              onTap: () {
                                _animateTo(0.0);
                                widget.onSave();
                              },
                            ),
                          ),
                          Expanded(
                            child: _SwipeActionButton(
                              color: widget.deleteColor,
                              icon: widget.deleteIcon,
                              label: widget.deleteLabel,
                              onTap: () {
                                _animateTo(0.0);
                                widget.onDelete();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(_offsetX, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFA), // 밝은 배경 유지
                    borderRadius: childRadius,
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.03 * (1.0 - easedProgress),
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: childRadius,
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
