import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';
import 'media_thumbnail.dart';

typedef SwipeDecisionCallback = void Function(bool keep);

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.item,
    required this.onDecision,
    this.onOpenDetail,
  });

  final MediaItem item;
  final SwipeDecisionCallback onDecision;
  final VoidCallback? onOpenDetail;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  double _angle = 0;
  late final AnimationController _flyController;
  Animation<Offset>? _flyAnimation;
  bool? _flyingKeep;

  static const _threshold = 120.0;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (_flyAnimation != null) {
          setState(() => _offset = _flyAnimation!.value);
        }
      });
  }

  @override
  void didUpdateWidget(covariant SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _offset = Offset.zero;
      _angle = 0;
      _flyingKeep = null;
      _flyController.reset();
    }
  }

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
      _angle = (_offset.dx / 300).clamp(-0.4, 0.4);
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final dx = _offset.dx;
    final vx = details.velocity.pixelsPerSecond.dx;
    if (dx > _threshold || vx > 900) {
      await _flyOut(keep: true);
    } else if (dx < -_threshold || vx < -900) {
      await _flyOut(keep: false);
    } else {
      setState(() {
        _offset = Offset.zero;
        _angle = 0;
      });
    }
  }

  Future<void> _flyOut({required bool keep}) async {
    HapticFeedback.lightImpact();
    _flyingKeep = keep;
    final end = Offset(keep ? 500 : -500, _offset.dy + (keep ? -40 : 40));
    _flyAnimation = Tween<Offset>(begin: _offset, end: end).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeOutCubic),
    );
    await _flyController.forward(from: 0);
    widget.onDecision(keep);
  }

  @override
  Widget build(BuildContext context) {
    final keepOpacity = (_offset.dx / _threshold).clamp(0.0, 1.0);
    final deleteOpacity = (-_offset.dx / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: widget.onOpenDetail,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: _angle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: MediaThumbnail(
                    item: widget.item,
                    fit: BoxFit.cover,
                    highQuality: true,
                  ),
                ),
              ),
              Positioned(
                top: 28,
                left: 24,
                child: _Stamp(
                  label: '删除',
                  color: AppColors.delete,
                  opacity: deleteOpacity,
                  tilt: -0.2,
                ),
              ),
              Positioned(
                top: 28,
                right: 24,
                child: _Stamp(
                  label: '保留',
                  color: AppColors.keep,
                  opacity: keepOpacity,
                  tilt: 0.2,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _MetaBar(item: widget.item),
              ),
              if (_flyingKeep != null)
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.opacity,
    required this.tilt,
  });

  final String label;
  final Color color;
  final double opacity;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: tilt,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBar extends StatelessWidget {
  const _MetaBar({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            item.isVideo
                ? CupertinoIcons.play_fill
                : item.isLivePhoto
                    ? CupertinoIcons.circle
                    : CupertinoIcons.photo,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.albumName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _sizeLabel(item.byteSize),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
