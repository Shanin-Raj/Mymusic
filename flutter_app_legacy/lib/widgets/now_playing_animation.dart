import 'package:flutter/material.dart';
import 'dart:math' as math;

class NowPlayingAnimation extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color? color;

  const NowPlayingAnimation({
    super.key,
    required this.isPlaying,
    this.size = 24,
    this.color,
  });

  @override
  State<NowPlayingAnimation> createState() => _NowPlayingAnimationState();
}

class _NowPlayingAnimationState extends State<NowPlayingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(NowPlayingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return _Bar(
            animation: _controller,
            index: index,
            color: color,
            totalBars: 4,
            size: widget.size,
          );
        }),
      ),
    );
  }
}

class _Bar extends AnimatedWidget {
  final int index;
  final Color color;
  final int totalBars;
  final double size;

  const _Bar({
    required Animation<double> animation,
    required this.index,
    required this.color,
    required this.totalBars,
    required this.size,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    // Create different phases and heights for each bar
    final double phase = (index / totalBars) * 0.5;
    double value = (animation.value + phase) % 1.0;
    
    // Sine-like movement
    double heightFactor = 0.2 + (0.8 * (0.5 + 0.5 * (index % 2 == 0 ? math.sin(value * 2 * math.pi) : math.cos(value * 2 * math.pi)).abs()));
    
    // Make it look more "EQ" like with some randomness or different frequencies
    if (index == 0) heightFactor = 0.3 + 0.7 * math.sin(animation.value * 2 * math.pi).abs();
    if (index == 1) heightFactor = 0.2 + 0.8 * math.cos((animation.value + 0.2) * 2 * math.pi * 1.5).abs();
    if (index == 2) heightFactor = 0.4 + 0.6 * math.sin((animation.value + 0.5) * 2 * math.pi * 0.8).abs();
    if (index == 3) heightFactor = 0.2 + 0.7 * math.cos((animation.value + 0.7) * 2 * math.pi * 1.2).abs();

    return SizedBox(
      height: size,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 3,
          height: size * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}
