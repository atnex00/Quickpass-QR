import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollable = true,
    this.baseColor,
    this.highlightColor,
  });

  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final bool scrollable;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final children = List.generate(
      itemCount,
      (i) => Padding(
        padding: EdgeInsets.only(bottom: i < itemCount - 1 ? 12 : 0),
        child: itemBuilder(i),
      ),
    );

    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      highlightColor:
          highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      child: scrollable
          ? ListView(children: children)
          : Column(children: children),
    );
  }
}
