import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

class TimerWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const TimerWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with WidgetLogMixin<TimerWidget> {
  @override
  AppWidget get logWidget => widget.widget;
  @override
  Function(AppWidget) get logOnUpdate => widget.onUpdate;

  Timer? _ticker;
  bool _running = false;

  // Stopwatch state
  int _elapsedMs = 0;
  List<int> _laps = [];

  // Timer (countdown) state
  int _remainingMs = 0;
  int _durationMs = 60000; // default 1 min

  bool get _isTimer => (widget.widget.data['mode'] as String?) == 'timer';

  @override
  void initState() {
    super.initState();
    _durationMs = ((widget.widget.data['durationMs'] as num?)?.toInt()) ?? 60000;
    _remainingMs = _durationMs;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleMode() {
    _stop();
    _reset();
    final newMode = _isTimer ? 'stopwatch' : 'timer';
    final data = addLog({...widget.widget.data, 'mode': newMode}, 'mode → $newMode');
    widget.onUpdate(widget.widget.copyWith(data: data));
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    final data = addLog({...widget.widget.data}, 'timer started');
    widget.onUpdate(widget.widget.copyWith(data: data));
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final baseElapsed = _isTimer ? (_durationMs - _remainingMs) : _elapsedMs;
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final delta = now - startTime + baseElapsed;
      setState(() {
        if (_isTimer) {
          _remainingMs = (_durationMs - delta).clamp(0, _durationMs);
          if (_remainingMs <= 0) {
            _stop();
          }
        } else {
          _elapsedMs = delta;
        }
      });
    });
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    setState(() => _running = false);
    final data = addLog({...widget.widget.data}, 'timer paused');
    widget.onUpdate(widget.widget.copyWith(data: data));
  }

  void _reset() {
    _stop();
    setState(() {
      _elapsedMs = 0;
      _remainingMs = _durationMs;
      _laps = [];
    });
    final data = addLog({...widget.widget.data}, 'timer reset');
    widget.onUpdate(widget.widget.copyWith(data: data));
  }

  void _lap() {
    if (!_running || _isTimer) return;
    setState(() => _laps.insert(0, _elapsedMs));
    final data = addLog({...widget.widget.data}, 'lap ${_laps.length}: ${_formatMs(_elapsedMs)}');
    widget.onUpdate(widget.widget.copyWith(data: data));
  }

  void _editDuration() {
    int minutes = _durationMs ~/ 60000;
    int seconds = (_durationMs % 60000) ~/ 1000;
    final minC = TextEditingController(text: minutes.toString());
    final secC = TextEditingController(text: seconds.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Duration'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: minC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: secC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sec'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final m = int.tryParse(minC.text) ?? 0;
              final s = int.tryParse(secC.text) ?? 0;
              final ms = (m * 60 + s) * 1000;
              if (ms > 0) {
                setState(() {
                  _durationMs = ms;
                  _remainingMs = ms;
                });
                final m2 = ms ~/ 60000;
                final s2 = (ms % 60000) ~/ 1000;
                final data = addLog({...widget.widget.data, 'durationMs': ms}, 'duration → ${m2}m ${s2}s');
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

  String _formatMs(int ms) {
    final totalSec = ms ~/ 1000;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final frac = (ms % 1000) ~/ 10;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${frac.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final displayMs = _isTimer ? _remainingMs : _elapsedMs;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.widget.title, style: theme.textTheme.titleMedium),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'stopwatch', label: Text('SW', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: 'timer', label: Text('Timer', style: TextStyle(fontSize: 11))),
              ],
              selected: {_isTimer ? 'timer' : 'stopwatch'},
              onSelectionChanged: (_) => _toggleMode(),
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isTimer && !_running ? _editDuration : null,
          child: Text(
            _formatMs(displayMs),
            style: theme.textTheme.displayLarge?.copyWith(
              fontFeatures: [const FontFeature.tabularFigures()],
              color: _isTimer && _remainingMs == 0 ? cs.error : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: _reset,
              icon: const Icon(Icons.replay),
              tooltip: 'Reset',
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              onPressed: _running ? _stop : _start,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              style: IconButton.styleFrom(
                backgroundColor: _running ? cs.error : cs.primary,
                foregroundColor: _running ? cs.onError : cs.onPrimary,
              ),
              iconSize: 32,
              tooltip: _running ? 'Pause' : 'Start',
            ),
            if (!_isTimer) ...[
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: _running ? _lap : null,
                icon: const Icon(Icons.flag),
                tooltip: 'Lap',
              ),
            ],
          ],
        ),
        if (_laps.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _laps.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lap ${_laps.length - i}', style: theme.textTheme.bodySmall),
                    Text(_formatMs(_laps[i]), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
