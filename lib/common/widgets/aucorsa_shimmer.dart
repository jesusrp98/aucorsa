import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AucorsaShimmer extends StatelessWidget {
  final Widget child;

  const AucorsaShimmer({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      highlightColor: Theme.of(context).colorScheme.surfaceBright,
      child: child,
    );
  }
}
