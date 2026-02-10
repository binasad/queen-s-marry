import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Wrapper widget for animated list items
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final bool vertical;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: vertical ? 50.0 : 0.0,
        horizontalOffset: vertical ? 0.0 : 50.0,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }
}

/// Animated list view builder wrapper
class AnimatedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final Axis scrollDirection;

  const AnimatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: itemCount,
        physics: physics,
        padding: padding,
        shrinkWrap: shrinkWrap,
        scrollDirection: scrollDirection,
        itemBuilder: (context, index) {
          return AnimatedListItem(
            index: index,
            vertical: scrollDirection == Axis.vertical,
            child: itemBuilder(context, index),
          );
        },
      ),
    );
  }
}

/// Animated horizontal list view
class AnimatedHorizontalListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const AnimatedHorizontalListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        physics: physics,
        padding: padding,
        itemBuilder: (context, index) {
          return AnimatedListItem(
            index: index,
            vertical: false,
            child: itemBuilder(context, index),
          );
        },
      ),
    );
  }
}
