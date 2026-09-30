import 'dart:async';

import 'package:flutter/material.dart';

/// Motion tokens and reusable transitions.
///
/// Everything animated in the app pulls its duration and curve from here so
/// the whole product decelerates the same way. The vocabulary is deliberately
/// small: content that appears *fades and lifts*, content that changes state
/// *cross-fades*, and content that navigates *slides along an axis*. Nothing
/// bounces or spins, which would undercut the seriousness of the subject.
class AppMotion {
  /// Press feedback. Fast enough to feel like the app is reacting to the
  /// finger, not reporting that it is alive.
  static const Duration instant = Duration(milliseconds: 120);

  /// Small state changes: chip selection, icon swaps, hover.
  static const Duration fast = Duration(milliseconds: 200);

  /// Default for most content entering a screen.
  static const Duration normal = Duration(milliseconds: 320);

  /// Reserved for the largest surfaces: sheets, full-screen heroes.
  static const Duration slow = Duration(milliseconds: 460);

  /// Per-item stagger in [StaggeredList]. Long enough to read as sequencing,
  /// short enough that a full list still arrives promptly.
  static const Duration stagger = Duration(milliseconds: 60);

  /// Standard easing: fast out of the gate, gentle landing. Matches the
  /// Material 3 "emphasized decelerate" feel without overshoot.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// For exits: leaves quickly so the screen never feels like it is lagging.
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// For elements that move between positions rather than appearing.
  static const Curve standard = Curves.easeOutCubic;

  const AppMotion._();
}

/// Entrance animation: fade up while lifting a short distance.
///
/// [delay] exists for staggered lists. It is driven by a plain timer rather
/// than an interval so the animation can be cancelled when the widget
/// unmounts — a ListView can recycle children mid-flight during a fast
/// scroll, and a `Future.delayed` that fires after dispose is the classic
/// source of "setState called after dispose" warnings.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
    this.offset = 16,
    this.curve = AppMotion.enter,
  });

  final Widget child;

  /// Hold this long before starting. Used by [StaggeredList].
  final Duration delay;

  final Duration duration;

  /// Vertical travel in logical pixels.
  final double offset;

  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Sequentially reveals its children with [FadeSlideIn].
///
/// Wraps each child in a `Builder` so callers can pass build callbacks
/// (`itemBuilder(index)`), keeping the stagger logic out of the call sites.
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.initialDelay = Duration.zero,
    this.step = AppMotion.stagger,
    this.maxStaggeredItems = 8,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Delay before the first item.
  final Duration initialDelay;

  /// Delay added per item.
  final Duration step;

  /// Items past this index appear immediately. Without a cap a long list would
  /// leave the last rows invisible for several seconds, which reads as a
  /// loading bug rather than as polish.
  final int maxStaggeredItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < itemCount; i++)
          FadeSlideIn(
            delay: i < maxStaggeredItems
                ? initialDelay + step * i
                : Duration.zero,
            child: Builder(builder: (context) => itemBuilder(context, i)),
          ),
      ],
    );
  }
}

/// Scale-down-on-press feedback for tappable surfaces.
///
/// Wrapping a whole card in an [InkWell] gives ripple but no sense of physical
/// press; this adds the missing 2% shrink so taps feel acknowledged even when
/// the ripple is subtle on a bordered surface.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.instant,
    reverseDuration: AppMotion.fast,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.scale,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    pressed ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    Widget result = ScaleTransition(scale: _scale, child: widget.child);

    if (!enabled) return result;

    result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: result,
    );

    if (widget.borderRadius == null) return result;

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Cross-fades between two states instead of snapping.
///
/// Used where content changes in place (a card flipping between a placeholder
/// and a loaded image, an icon switching to a success check). [AnimatedSwitcher]
/// with a matching layout builder avoids the size jump you get by default.
class AppCrossFade extends StatelessWidget {
  const AppCrossFade({
    super.key,
    required this.child,
    this.duration = AppMotion.fast,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [...previousChildren, ?currentChild],
        );
      },
      child: child,
    );
  }
}

/// Page route with a shared-axis style push.
///
/// The previous screen drifts slightly and fades while the incoming screen
/// slides in from the trailing edge. Material's default for Android is a
/// vertical rise-from-bottom, which is wrong for a horizontally tabbed app
/// where most navigation is lateral.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget page, super.settings})
    : super(
        transitionDuration: AppMotion.normal,
        reverseTransitionDuration: AppMotion.fast,
        pageBuilder: (context, _, _) => page,
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.enter,
            reverseCurve: AppMotion.exit,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              // Fade faster than the slide so the incoming screen is legible
              // before it has finished travelling.
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0, 0.7),
                ),
              ),
              child: child,
            ),
          );
        },
      );
}

/// Bottom-sheet route that lifts and fades rather than sliding the full sheet.
class AppSheetRoute<T> extends PageRouteBuilder<T> {
  AppSheetRoute({required Widget page, super.settings})
    : super(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: AppMotion.slow,
        reverseTransitionDuration: AppMotion.fast,
        pageBuilder: (context, _, _) => page,
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.enter,
            reverseCurve: AppMotion.exit,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      );
}

/// Route for a destination that is pushed onto the stack rather than drilled
/// into: notifications, and the detail views reached from a list.
///
/// These travel the full width of the screen, which is the platform
/// convention for "something new was added to the stack" and is what makes the
/// back gesture legible. [AppPageRoute] is the weaker variant used for
/// lateral drill-downs where a full-width slide would imply a larger context
/// switch than is actually happening.
class AppPushRoute<T> extends PageRouteBuilder<T> {
  AppPushRoute({required Widget page, super.settings})
    : super(
        transitionDuration: AppMotion.slow,
        reverseTransitionDuration: AppMotion.fast,
        pageBuilder: (context, _, _) => page,
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.enter,
            reverseCurve: AppMotion.exit,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            // The outgoing screen recedes slightly rather than just fading,
            // which gives the transition depth without a drop shadow.
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.86, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
}
