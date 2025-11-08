import 'package:flutter/material.dart';
import 'animated_list_tile.dart';

/// Helper widget for staggering multiple child animations
class StaggeredAnimation extends StatelessWidget {
  final List<Widget> children;
  final Duration delayBetween;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  const StaggeredAnimation({
    super.key,
    required this.children,
    this.delayBetween = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    this.offset = const Offset(0, 0.02),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return AnimatedListTile(
          delay: delayBetween * index,
          duration: duration,
          offset: offset,
          curve: curve,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Staggered list builder for ListView
class StaggeredListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration delayBetween;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.delayBetween = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    this.offset = const Offset(0, 0.02),
    this.curve = Curves.easeOutCubic,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return AnimatedListTile(
          delay: delayBetween * index,
          duration: duration,
          offset: offset,
          curve: curve,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

