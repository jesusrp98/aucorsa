import 'package:flutter/material.dart';

/// Widget that will inform the user about a specific topic.
/// Information could be transmitted via text, icons or any other widget.
///
/// Also, the user could interact with this view using the [action] parameter.
class BigTip extends StatelessWidget {
  /// Widget representing the main information point of the view.
  ///
  /// If this parameters holds a [Icon] widget, an automatic theme
  /// will be applied, setting its size to 100, and using the caption
  /// text style's color by default.
  final Widget? child;

  /// Space between the [child] and the [title]. Default value is 16.
  final double childSpace;

  /// Space between `tile` and [subtitle] widgets. Default value is 8.
  final double subtitleSpace;

  /// Outter padding of the view. Default is 32.
  final EdgeInsets padding;

  /// Main title widget of the view. Usually a [Text] widget.
  final Widget? title;

  /// Secondary widget of the view. Usually a [Text] widget.
  final Widget? subtitle;

  /// Optional parameter that allows to place an 'actionable' widget at
  /// the bottom of the view.
  final Widget? action;

  const BigTip({
    super.key,
    this.child,
    this.childSpace = 16,
    this.subtitleSpace = 8,
    this.padding = const EdgeInsets.all(32),
    this.title,
    this.subtitle,
    this.action,
  }) : assert(
          child != null || title != null || subtitle != null,
          'One of the these parameters should not be null',
        );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action != null) const Flexible(child: SizedBox.expand()),
            if (child != null)
              IconTheme.merge(
                data: Theme.of(context).iconTheme.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 128,
                    ),
                child: child!,
              ),
            if (child != null && (title != null || subtitle != null))
              SizedBox(height: childSpace),
            if (title != null)
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!,
                textAlign: TextAlign.center,
                child: title!,
              ),
            if (subtitle != null) ...[
              if (title != null) SizedBox(height: subtitleSpace),
              DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                child: subtitle!,
              ),
            ],
            if (action != null) ...[
              const Flexible(child: SizedBox.expand()),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
