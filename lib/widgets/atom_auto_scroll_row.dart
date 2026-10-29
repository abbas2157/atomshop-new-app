import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// A horizontal row of fixed-width items that drifts slowly on its own
/// (Home's categories, "Hot right now" and brand partners).
///
/// Stops while the customer touches it and starts again a few seconds after
/// they let go. At the end it waits, glides back to the start and carries
/// on. Stays still when the phone asks for reduced motion, when [autoScroll]
/// is off (skeletons) or when everything already fits.
class AtomAutoScrollRow extends StatefulWidget {
  const AtomAutoScrollRow({
    super.key,
    required this.height,
    required this.itemWidth,
    required this.itemCount,
    required this.itemBuilder,
    this.gutter = 0,
    this.spacing = 12,
    this.autoScroll = true,
    this.speed = 20,
  });

  final double height;
  final double itemWidth;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Space before the first and after the last item.
  final double gutter;
  final double spacing;
  final bool autoScroll;

  /// Logical pixels per second.
  final double speed;

  @override
  State<AtomAutoScrollRow> createState() => _AtomAutoScrollRowState();
}

class _AtomAutoScrollRowState extends State<AtomAutoScrollRow> with SingleTickerProviderStateMixin {
  static const _resumeAfter = Duration(seconds: 3);
  static const _pauseAtEnds = Duration(seconds: 2);

  final _controller = ScrollController();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  bool _held = false;
  bool _rewinding = false;
  Timer? _wait;

  bool get _enabled => widget.autoScroll && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AtomAutoScrollRow old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_enabled && !_ticker.isActive && !_held && _wait == null && !_rewinding) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!_enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 0.0 : (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.maxScrollExtent <= 0) return;
    final next = position.pixels + widget.speed * dt;
    if (next < position.maxScrollExtent) {
      _controller.jumpTo(next);
      return;
    }
    _controller.jumpTo(position.maxScrollExtent);
    _ticker.stop();
    _wait = Timer(_pauseAtEnds, _rewind);
  }

  Future<void> _rewind() async {
    _wait = null;
    if (!mounted || _held || !_controller.hasClients) return;
    _rewinding = true;
    await _controller.animateTo(0, duration: const Duration(milliseconds: 1200), curve: Curves.easeInOut);
    _rewinding = false;
    if (!mounted || _held) return;
    _wait = Timer(_pauseAtEnds, () {
      _wait = null;
      if (mounted) _sync();
    });
  }

  bool _onScroll(UserScrollNotification n) {
    _wait?.cancel();
    _wait = null;
    if (n.direction != ScrollDirection.idle) {
      _held = true;
      _ticker.stop();
    } else {
      _wait = Timer(_resumeAfter, () {
        _wait = null;
        _held = false;
        if (mounted) _sync();
      });
    }
    return false;
  }

  @override
  void dispose() {
    _wait?.cancel();
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: widget.gutter),
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
          itemBuilder: (context, i) => SizedBox(width: widget.itemWidth, child: widget.itemBuilder(context, i)),
        ),
      ),
    );
  }
}
