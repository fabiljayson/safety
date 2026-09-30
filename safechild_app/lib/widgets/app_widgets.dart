import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Semantic status rendering.
///
/// This replaces the emoji the app previously used to carry status. Emoji are
/// a poor fit here for three reasons: they render differently per platform and
/// per OS version, they cannot be re-coloured to match a theme or meet a
/// contrast target, and they carry no typographic weight so they sit oddly next
/// to real text. A vector icon plus a real text label in the theme's own type
/// scale is stable, accessible, and translatable.
enum StatusTone { urgent, verified, pending, resolved, adultMissing, neutral }

/// Resolves the icon/label/colour triple for a value, so callers can render
/// badges without repeating the switch.
class StatusStyle {
  const StatusStyle({
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final Color color;
  final Color onColor;

  static StatusStyle of(BuildContext context, StatusTone tone) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return switch (tone) {
      StatusTone.urgent => StatusStyle(
        icon: Icons.campaign_rounded,
        color: colors.urgent,
        onColor: colors.onStatus,
      ),
      StatusTone.verified => StatusStyle(
        icon: Icons.verified_rounded,
        color: colors.verified,
        onColor: colors.onStatus,
      ),
      StatusTone.pending => StatusStyle(
        icon: Icons.schedule_rounded,
        color: colors.pending,
        onColor: colors.onStatus,
      ),
      StatusTone.resolved => StatusStyle(
        icon: Icons.task_alt_rounded,
        color: colors.resolved,
        onColor: colors.onStatus,
      ),
      StatusTone.adultMissing => StatusStyle(
        icon: Icons.person_rounded,
        color: colors.adultMissing,
        onColor: colors.onStatus,
      ),
      StatusTone.neutral => StatusStyle(
        icon: Icons.circle_outlined,
        color: scheme.onSurfaceVariant,
        onColor: scheme.onSurface,
      ),
    };
  }

  /// Maps a backend alert type to its tone. Centralised so a new alert type
  /// cannot be added in one screen and forgotten in another.
  static StatusTone toneForAlertType(String? alertType) {
    return switch (alertType) {
      'child_missing' || 'kidnapping' => StatusTone.urgent,
      'adult_missing' => StatusTone.adultMissing,
      'wanted_person' || 'wanted' => StatusTone.urgent,
      _ => StatusTone.neutral,
    };
  }
}

/// Compact pill: coloured fill, white glyph, uppercase tracked label.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.iconSize = 12,
    this.dense = false,
  });

  /// Rendered in the theme's labelSmall style, so it scales with the platform
  /// text-size setting rather than pinning a font size like the old
  /// hardcoded `fontSize: 10`.
  final String label;
  final StatusTone tone;
  final double iconSize;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(context, tone);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : AppSpacing.sm,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: iconSize, color: style.onColor),
          SizedBox(width: dense ? 3 : AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: style.onColor,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 10 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tinted variant for lower-emphasis rows: icon in the status colour on a
/// muted background, with the label in normal body colour.
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    required this.tone,
    this.iconSize = 14,
  });

  final String label;
  final StatusTone tone;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(context, tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: iconSize, color: style.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: style.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered surface with no elevation. The default `Card` look in this app
/// previously used shadow + border radius 25; a hairline border reads flatter
/// and more professional than a drop shadow, and it survives dark mode better.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor ?? colors.borderSubtle),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: content,
    );
  }
}

/// Section heading with an optional trailing action. Gives every screen the
/// same header rhythm instead of each one inventing its own padding and size.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Flat scrim used behind text that sits on top of a photograph.
///
/// This is deliberately a solid translucent colour rather than the vertical
/// transparent-to-black gradient it replaces. A gradient over an image is the
/// main reason the previous card design looked decorative; a flat scrim keeps
/// the text legible with predictable contrast and stops the image from
/// washing out toward the bottom.
class ImageScrim extends StatelessWidget {
  const ImageScrim({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.imageScrim,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}

/// Empty / error state. Replaces ad-hoc "no data" text blocks with a
/// consistent icon-plus-message-plus-optional-action layout.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
