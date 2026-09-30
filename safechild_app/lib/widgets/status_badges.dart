import 'package:flutter/material.dart';

import '../models/missing_child.dart';
import '../widgets/app_widgets.dart';

/// Alert-type and review-state rendering for a missing-person record.
///
/// The app previously rendered these as emoji inside strings, e.g. an siren
/// glyph prefixed onto the localised 'filter_wanted' label. Four screens each
/// had their own
/// copy of that conditional chain with hardcoded `Colors.red[100]` /
/// `Colors.purple[900]` and a hardcoded `fontSize: 10`, which meant the badge
/// did not respond to the platform text-size setting and its colours ignored
/// dark mode. Both problems are resolved by going through the theme here.
///
/// A translation lookup is needed to build the label, so this takes a
/// [localizations] callback rather than reaching for a context extension: the
/// Flutter app has no `BuildContext`-based localization provider.
class AlertTypeBadge extends StatelessWidget {
  const AlertTypeBadge({
    super.key,
    required this.child,
    required this.label,
    this.dense = false,
    this.uppercase = false,
  });

  final MissingChild child;

  /// Already-localised text for this alert type.
  final String label;

  final bool dense;

  /// The detail header used to call `.toUpperCase()` on the localised string,
  /// which is wrong for French (accents must stay intact and French does not
  /// use uppercase as a styling device). Kept opt-in for that one call site.
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: uppercase ? label.toUpperCase() : label,
      tone: StatusStyle.toneForAlertType(child.alertType),
      dense: dense,
    );
  }
}

/// Review state: verified / pending / resolved.
///
/// Replaces the previous inline interpolation of a check glyph versus an
/// hourglass glyph around the localised label. This is
/// a [Row] of a [StatusTag] rather than a badge because it sits in a subtitle
/// next to the age, where a filled pill would compete with the name above it.
class ReviewStateTag extends StatelessWidget {
  const ReviewStateTag({
    super.key,
    required this.isVerified,
    required this.isResolved,
    required this.certifiedLabel,
    required this.pendingLabel,
    required this.resolvedLabel,
    this.iconSize = 14,
  });

  final bool isVerified;
  final bool isResolved;
  final String certifiedLabel;
  final String pendingLabel;
  final String resolvedLabel;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    // Resolved wins over verified: a found person is the terminal state, and
    // showing "certified" for a closed case would be misleading.
    final (label, tone) = isResolved
        ? (resolvedLabel, StatusTone.resolved)
        : isVerified
        ? (certifiedLabel, StatusTone.verified)
        : (pendingLabel, StatusTone.pending);

    return StatusTag(label: label, tone: tone, iconSize: iconSize);
  }
}
