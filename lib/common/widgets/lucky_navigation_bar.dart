import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

/// A customizable navigation bar widget for Flutter applications.
///
/// The [LuckyNavigationBar] displays a row of navigation destinations,
/// allowing users to switch between different sections of the app.
/// It supports an optional trailing widget, such as a button or icon,
/// and highlights the currently selected destination.
///
/// The navigation bar has a fixed height and padding, defined by
/// [height] and [paddingValue] respectively.
///
/// Example usage:
/// ```dart
/// LuckyNavigationBar(
///   destinations: [
///     NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
///     NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
///   ],
///   selectedIndex: 0,
///   onDestinationSelected: (index) {
///     // Handle navigation
///   },
///   trailing: IconButton(
///     icon: Icon(Icons.settings),
///     onPressed: () {},
///   ),
/// )
/// ```
///
/// {@tool snippet}
/// See also:
///  * [NavigationDestination], which defines each destination.
/// {@end-tool}
class LuckyNavigationBar extends StatefulWidget {
  static const paddingValue = 21.0;
  static const height = 62.0;

  /// The list of navigation destinations to display.
  final List<NavigationDestination> destinations;

  ///Callback triggered when a destination is selected, providing the index.
  final ValueChanged<int> onDestinationSelected;

  ///The index of the currently selected destination. Defaults to 0.
  final int selectedIndex;

  /// An optional widget displayed at the end of the navigation bar.
  final Widget? trailing;

  const new({
    required this.destinations,
    required this.onDestinationSelected,
    this.selectedIndex = 0,
    this.trailing,
    super.key,
  });

  @override
  State<LuckyNavigationBar> createState() => _LuckyNavigationBarState();
}

class _LuckyNavigationBarState extends State<LuckyNavigationBar>
    with SingleTickerProviderStateMixin {
  static const internalPadding = EdgeInsets.symmetric(horizontal: 4);
  static const scalingFactor = 0.016;
  static const itemSpacing = -8.0;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  var _itemSpacing = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: kThemeAnimationDuration,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(() => _itemSpacing = itemSpacing),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LuckyNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onTabSelected(widget.selectedIndex),
      );
    }
  }

  void _onTapDown(PointerDownEvent details) => _controller.forward();

  void _onPointerUp(PointerEvent details) => _controller.reverse();

  void onTabSelected(int index) => widget.onDestinationSelected(index);

  @override
  Widget build(BuildContext context) {
    final isIOS =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Stack(
        children: [
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: LuckyNavigationBar.paddingValue + LuckyNavigationBar.height,
            child: _LuckyNavigationBarBrim(),
          ),
          SafeArea(
            bottom: !isIOS,
            minimum: const EdgeInsets.all(
              LuckyNavigationBar.paddingValue,
            ).copyWith(top: 0),
            child: Row(
              spacing: 8,
              mainAxisAlignment: widget.trailing == null
                  ? .center
                  : .spaceBetween,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: resolveWidth),
                    child: Listener(
                      onPointerDown: _onTapDown,
                      onPointerUp: _onPointerUp,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (_, child) => Transform.scale(
                          scale: 1 + _scaleAnimation.value * scalingFactor,
                          child: child,
                        ),
                        child: _LuckyNavigationBarView(
                          tabIndex: widget.selectedIndex,
                          destinations: widget.destinations,
                          onTabChanged: onTabSelected,
                          child: SizedBox(
                            height: LuckyNavigationBar.height,
                            child: Material(
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(
                                  LuckyNavigationBar.height / 2,
                                ),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: .4),
                                  width: 0.5,
                                ),
                              ),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              elevation: 1,
                              child: Padding(
                                padding: internalPadding,
                                child: Row(
                                  mainAxisAlignment: .spaceEvenly,
                                  spacing: _itemSpacing,
                                  children: List.generate(
                                    widget.destinations.length,
                                    (index) => Expanded(
                                      child: _LuckyNavigationBarItem(
                                        destination: widget.destinations[index],
                                        selected: widget.selectedIndex == index,
                                        onTap: () => onTabSelected(index),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ?widget.trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get resolveWidth {
    const maxWidth = 512.0;

    if (widget.destinations.length == 2) return 188;

    if (widget.trailing != null) return maxWidth;

    if (widget.destinations.length == 3) return 274;

    return maxWidth;
  }
}

class _LuckyNavigationBarBrim extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuckyNavigationBarItem extends StatelessWidget {
  final NavigationDestination destination;
  final VoidCallback onTap;
  final bool selected;

  const new({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final selectedColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constrains) {
        final usePortraitLayout = constrains.maxWidth < 150;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: ColorTween(
                  begin: unselectedColor,
                  end: selected ? selectedColor : unselectedColor,
                ),
                duration: kThemeAnimationDuration,
                curve: Curves.easeInOutCubic,
                builder: (_, color, _) => Flex(
                  direction: usePortraitLayout ? .vertical : .horizontal,
                  spacing: usePortraitLayout ? 0 : 8,
                  mainAxisSize: .min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: selected ? 1 : 0),
                      duration: kThemeAnimationDuration,
                      curve: Curves.easeInOutCubic,
                      builder: (_, value, _) => IconTheme.merge(
                        data: IconThemeData(
                          color: color,
                          fill: value,
                          size: 28,
                        ),
                        child: destination.icon,
                      ),
                    ),
                    Text(
                      destination.label,
                      style: TextStyle(
                        color: color,
                        fontSize: usePortraitLayout ? 12 : null,
                      ),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LuckyNavigationBarView extends StatefulWidget {
  final List<NavigationDestination> destinations;
  final int tabIndex;
  final Widget child;
  final ValueChanged<int> onTabChanged;

  const new({
    required this.destinations,
    required this.child,
    required this.tabIndex,
    required this.onTabChanged,
  });

  @override
  State<_LuckyNavigationBarView> createState() =>
      _LuckyNavigationBarViewState();
}

class _LuckyNavigationBarViewState extends State<_LuckyNavigationBarView>
    with SingleTickerProviderStateMixin {
  late int tabCount = widget.destinations.length;

  bool _isDown = false;
  bool _isDragging = false;

  late double xAlign = computeAlignmentForTab(widget.tabIndex);

  double computeAlignmentForTab(int tabIndex) {
    final relativeTabIndex = (tabIndex / (tabCount - 1)).clamp(0.0, 1.0);

    return (relativeTabIndex * 2) - 1; // -1 to 1
  }

  @override
  void didUpdateWidget(covariant _LuckyNavigationBarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tabIndex != widget.tabIndex) {
      setState(() => xAlign = computeAlignmentForTab(widget.tabIndex));
    }

    if (oldWidget.destinations != widget.destinations) {
      setState(() => tabCount = widget.destinations.length);
    }
  }

  double _getAlignmentFromGlobalPostition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);

    // Calculate the effective draggable range
    // The indicator moves within the tab bar, but has its own width (1/tabCount of total)
    final indicatorWidth = 1.0 / tabCount; // Relative width of indicator
    final draggableRange =
        1.0 - indicatorWidth; // Range the indicator center can move
    final padding = indicatorWidth / 2; // Padding on each side

    // Map the drag position to the draggable range
    final rawRelativeX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final normalizedX = (rawRelativeX - padding) / draggableRange;

    // Apply rubber band resistance for overdrag
    final adjustedRelativeX = _applyRubberBandResistance(normalizedX);

    return (adjustedRelativeX * 2) - 1; // Convert to -1:1 range
  }

  void _onDragDown(DragDownDetails details) => setState(() {
    _isDown = true;
    xAlign = _getAlignmentFromGlobalPostition(details.globalPosition);
  });

  void _onDragUpdate(DragUpdateDetails details) => setState(() {
    _isDragging = true;
    xAlign = _getAlignmentFromGlobalPostition(details.globalPosition);
  });

  // Apply rubber band resistance similar to iOS scroll views
  double _applyRubberBandResistance(double value) {
    const resistance = 0.2; // Lower values = more resistance
    const maxOverdrag = 0.3; // Maximum overdrag as fraction of normal range

    // Overdrag to the left
    if (value < 0) {
      final overdrag = -value;
      final resistedOverdrag = overdrag * resistance;

      return -resistedOverdrag.clamp(0.0, maxOverdrag);
    }

    // Overdrag to the right
    if (value > 1) {
      final overdrag = value - 1;
      final resistedOverdrag = overdrag * resistance;

      return 1 + resistedOverdrag.clamp(0.0, maxOverdrag);
    }

    // Normal range, no resistance
    return value;
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _isDown = false;
    });

    final currentRelativeX = (xAlign + 1) / 2; // Convert from -1:1 to 0:1
    final tabWidth = 1.0 / tabCount;

    // Determine target tab based on position and velocity
    int targetTabIndex;

    // Handle overdrag scenarios first
    if (currentRelativeX < 0) {
      // Overdragged to the left - snap to first tab
      targetTabIndex = 0;
    } else if (currentRelativeX > 1) {
      // Overdragged to the right - snap to last tab
      targetTabIndex = tabCount - 1;
    } else {
      targetTabIndex = (currentRelativeX / tabWidth).round().clamp(
        0,
        tabCount - 1,
      );
    }
    xAlign = computeAlignmentForTab(targetTabIndex);

    // Notify parent of tab change if different from current
    if (targetTabIndex != widget.tabIndex) {
      widget.onTabChanged(targetTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetAlignment = computeAlignmentForTab(widget.tabIndex);

    return GestureDetector(
      onHorizontalDragDown: _onDragDown,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => setState(() {
        _isDragging = false;
        _isDown = false;
      }),
      child: VelocityMotionBuilder(
        converter: const SingleMotionConverter(),
        value: xAlign,
        motion: _isDragging
            ? const .interactiveSpring(snapToEnd: true)
            : const .bouncySpring(snapToEnd: true),
        builder: (context, value, velocity, child) {
          final alignment = Alignment(value, 0);

          return SingleMotionBuilder(
            motion: const .snappySpring(
              snapToEnd: true,
              duration: kThemeAnimationDuration,
            ),
            value: _isDown || (alignment.x - targetAlignment).abs() > 0.30
                ? 1.0
                : 0.0,
            builder: (_, thickness, child) => Stack(
              clipBehavior: Clip.none,
              children: [
                child!,
                _LuckyNavigationBarSelectorView(
                  velocity: velocity,
                  alignment: alignment,
                  thickness: thickness,
                  destinationsLength: widget.destinations.length,
                ),
              ],
            ),
            child: widget.child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _LuckyNavigationBarSelectorView extends StatelessWidget {
  final int destinationsLength;
  final double velocity;
  final Alignment alignment;
  final double thickness;

  const new({
    required this.destinationsLength,
    required this.velocity,
    required this.alignment,
    required this.thickness,
  });

  /// Creates a jelly transform matrix based on velocity
  /// for organic squash and stretch effect
  Matrix4 _buildJellyTransform({
    required Offset velocity,
    required double maxDistortion,
    required double velocityScale,
  }) {
    // Calculate the magnitude of velocity to determine distortion intensity
    final speed = velocity.distance;

    // Normalize velocity direction
    final direction = speed > 0 ? velocity / speed : Offset.zero;

    // Apply a scaling factor to make the effect more pronounced
    final distortionFactor =
        (speed / velocityScale).clamp(0.0, 1.0) * maxDistortion;

    if (distortionFactor == 0) {
      return Matrix4.identity();
    }

    // Create squash and stretch effect
    // Squash in the direction of movement, stretch perpendicular to it
    final squashX = 1.0 - (direction.dx.abs() * distortionFactor * 0.5);
    final squashY = 1.0 - (direction.dy.abs() * distortionFactor * 0.5);
    final stretchX = 1.0 + (direction.dy.abs() * distortionFactor * 0.3);
    final stretchY = 1.0 + (direction.dx.abs() * distortionFactor * 0.3);

    // Combine squash and stretch effects
    final scaleX = squashX * stretchX;
    final scaleY = squashY * stretchY;

    return Matrix4.identity()..scaleByDouble(scaleX, scaleY, scaleX, 1);
  }

  double _resolveWidthFactor(double width) =>
      (1 -
          (destinationsLength - 1) *
              (_LuckyNavigationBarState.itemSpacing / width)) /
      destinationsLength;

  @override
  Widget build(BuildContext context) {
    final rect = RelativeRect.lerp(
      RelativeRect.fill,
      const RelativeRect.fromLTRB(-8, -8, -8, -8),
      thickness,
    );

    return Positioned.fill(
      left: 4,
      right: 4,
      top: 4,
      bottom: 4,
      child: LayoutBuilder(
        builder: (context, constraints) => FractionallySizedBox(
          widthFactor: _resolveWidthFactor(constraints.maxWidth),
          alignment: alignment,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRelativeRect(
                rect: rect!,
                child: SingleMotionBuilder(
                  motion: Motion.bouncySpring(
                    duration: kThemeAnimationDuration * 2,
                  ),
                  value: velocity,
                  builder: (context, velocity, child) => Transform(
                    alignment: Alignment.center,
                    transform: _buildJellyTransform(
                      velocity: Offset(velocity, 0),
                      maxDistortion: .8,
                      velocityScale: 10,
                    ),
                    child: child,
                  ),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.16),
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(
                          LuckyNavigationBar.height,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
