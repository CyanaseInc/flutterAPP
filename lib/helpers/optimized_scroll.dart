import 'package:flutter/material.dart';

/// An optimized ListView that uses caching and lazy loading
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool reverse;

  const OptimizedListView({
    Key? key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.reverse = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      itemCount: children.length,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      reverse: reverse,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }
}

/// An optimized PageView that uses caching and smooth transitions
class OptimizedPageView extends StatelessWidget {
  final List<Widget> children;
  final PageController? controller;
  final ValueChanged<int>? onPageChanged;
  final bool physics;
  final double viewportFraction;

  const OptimizedPageView({
    Key? key,
    required this.children,
    this.controller,
    this.onPageChanged,
    this.physics = true,
    this.viewportFraction = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      physics: physics
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }
}

/// An optimized SingleChildScrollView that uses caching
class OptimizedSingleChildScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const OptimizedSingleChildScrollView({
    Key? key,
    required this.child,
    this.controller,
    this.physics,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: RepaintBoundary(
        child: child,
      ),
    );
  }
}

/// A mixin to optimize scrolling performance
mixin ScrollOptimizationMixin<T extends StatefulWidget> on State<T> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Implement scroll optimization logic here
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more data or handle end of scroll
    }
  }

  ScrollController get scrollController => _scrollController;
}
