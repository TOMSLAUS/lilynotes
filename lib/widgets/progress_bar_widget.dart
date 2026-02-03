import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

class ProgressBarWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const ProgressBarWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ProgressBarWidget> createState() => _ProgressBarWidgetState();
}

class _ProgressBarWidgetState extends State<ProgressBarWidget> with WidgetLogMixin<ProgressBarWidget> {
  @override
  AppWidget get logWidget => widget.widget;
  @override
  Function(AppWidget) get logOnUpdate => widget.onUpdate;

  late TextEditingController _titleController;
  late ConfettiController _confettiController;
  OverlayEntry? _confettiOverlay;
  final _barKey = GlobalKey();

  int get _current => (widget.widget.data['current'] as num?)?.toInt() ?? 0;
  int get _target => (widget.widget.data['target'] as num?)?.toInt() ?? 10;
  double get _progress => _target > 0 ? _current / _target : 0;
  int get _percent => (_progress * 100).round();
  bool get _complete => _current >= _target && _target > 0;

  void _setCurrent(int v) {
    final wasComplete = _complete;
    final prev = _current;
    var data = {...widget.widget.data, 'current': v.clamp(0, 999999)};
    data = addLog(data, 'progress: $prev → ${v.clamp(0, 999999)}');
    widget.onUpdate(widget.widget.copyWith(
      title: _titleController.text,
      data: data,
    ));
    final nowComplete = v.clamp(0, 999999) >= _target && _target > 0;
    if (!wasComplete && nowComplete) {
      _showConfetti();
    }
  }

  void _showConfetti() {
    _removeConfettiOverlay();
    final overlay = Overlay.of(context);
    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));

    _confettiController.play();
    _confettiOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: pos.dx,
        top: pos.dy,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 12,
          maxBlastForce: 12,
          minBlastForce: 4,
          emissionFrequency: 0.06,
          gravity: 0.3,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.secondary,
            Colors.amber,
            Colors.pink,
          ],
        ),
      ),
    );
    overlay.insert(_confettiOverlay!);
    Future.delayed(const Duration(seconds: 7), _removeConfettiOverlay);
  }

  void _removeConfettiOverlay() {
    _confettiOverlay?.remove();
    _confettiOverlay = null;
  }

  void _editTarget() {
    final controller = TextEditingController(text: _target.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final t = int.tryParse(controller.text);
              if (t != null && t > 0) {
                var data = {...widget.widget.data, 'target': t};
                data = addLog(data, 'target: $_target → $t');
                widget.onUpdate(widget.widget.copyWith(data: data));
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void didUpdateWidget(ProgressBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widget.id != widget.widget.id) {
      _titleController.text = widget.widget.title;
    }
  }

  @override
  void dispose() {
    _removeConfettiOverlay();
    _titleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final barColor = _complete ? cs.tertiary : cs.primary;

    return Column(
      key: _barKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          onChanged: (_) => widget.onUpdate(widget.widget.copyWith(title: _titleController.text)),
          style: theme.textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'Goal title...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress.clamp(0, 1),
            minHeight: 14,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '$_percent%',
              style: theme.textTheme.titleSmall?.copyWith(
                color: _complete ? cs.tertiary : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              ' \u2014 $_current/$_target',
              style: theme.textTheme.bodySmall,
            ),
            if (_complete) ...[
              const SizedBox(width: 6),
              Icon(Icons.celebration, size: 20, color: cs.tertiary),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              onPressed: _current > 0 ? () => _setCurrent(_current - 1) : null,
              icon: const Icon(Icons.remove, size: 32),
              iconSize: 28,
            ),
            const SizedBox(width: 16),
            Text(
              '$_current',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 16),
            IconButton.outlined(
              onPressed: () => _setCurrent(_current + 1),
              icon: const Icon(Icons.add, size: 32),
              iconSize: 28,
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _editTarget,
              child: Text('Target: $_target'),
            ),
          ],
        ),
      ],
    );
  }
}
