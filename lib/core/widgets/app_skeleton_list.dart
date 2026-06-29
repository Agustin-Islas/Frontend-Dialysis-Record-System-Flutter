import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton placeholder for list-based screens.
///
/// Replaces [CircularProgressIndicator] full-screen loaders
/// with a shimmer effect that mirrors the final layout.
class AppSkeletonList extends StatelessWidget {
  /// Number of skeleton items to display.
  final int itemCount;

  /// Builder for each skeleton item. Should return a widget
  /// with the same approximate layout as the real content.
  /// Wrap text and containers with [Bone] for automatic shimmer.
  final Widget Function(BuildContext context, int index) itemBuilder;

  const AppSkeletonList({
    super.key,
    this.itemCount = 4,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// A simple skeleton card matching the common card layout.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Bone.text(words: 2),
            const SizedBox(height: 8),
            const Bone.text(words: 4),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Bone.text(words: 2)),
                const SizedBox(width: 12),
                Expanded(child: Bone.text(words: 2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen skeleton loading state with optional header.
class AppSkeletonScreen extends StatelessWidget {
  /// Optional title to show above the skeleton content.
  final String? title;

  /// Number of skeleton cards.
  final int itemCount;

  const AppSkeletonScreen({
    super.key,
    this.title,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (title != null) ...[
            Bone.text(words: 1, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
          ],
          for (int i = 0; i < itemCount; i++) const AppSkeletonCard(),
        ],
      ),
    );
  }
}
