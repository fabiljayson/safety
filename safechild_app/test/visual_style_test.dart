import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the two visual rules that were applied by hand across every screen:
/// no emoji, and no gradients.
///
/// These are style rules rather than logic, so nothing else fails when one is
/// broken — a reviewer would have to catch it by eye. Encoding them as tests
/// makes the rule self-enforcing and keeps the "professional, typographic"
/// direction from eroding one copy-pasted filter chip at a time.
void main() {
  /// Emoji and pictographic ranges. Deliberately wide: dingbats, arrows and
  /// the variation selector are included because those also render as
  /// pictographs on device even though they are not in the 1F000 block.
  final emojiPattern = RegExp(
    '[\u{1F000}-\u{1FAFF}'
    '\u{2600}-\u{27BF}'
    '\u{2B00}-\u{2BFF}'
    '\u{2190}-\u{21FF}'
    '\u{2B05}-\u{2B07}'
    '\u{23E9}-\u{23FA}'
    '\u{24C2}'
    '\u{25AA}-\u{25FE}'
    '\u{FE0F}'
    '\u{200D}]',
    unicode: true,
  );

  final gradientPattern = RegExp(
    r'(LinearGradient|RadialGradient|SweepGradient)\s*\(',
  );

  List<File> dartFilesIn(String dir) {
    final root = Directory(dir);
    if (!root.existsSync()) return const [];
    return root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  final files = dartFilesIn('lib');

  test('lib/ contains Dart sources to scan', () {
    // Guards the rest of this group against silently passing if the path is
    // wrong, which is the usual failure mode of a source-scanning test.
    expect(files, isNotEmpty, reason: 'no Dart files found under lib/');
  });

  group('emoji policy', () {
    test('no emoji anywhere in lib/', () {
      final violations = <String>[];

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final match = emojiPattern.firstMatch(lines[i]);
          if (match != null) {
            violations.add(
              '${file.path}:${i + 1}: found ${match.group(0)} '
              '(${match.group(0)!.runes.map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(' ')})',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Emoji must not be used in the UI: they render inconsistently across '
            'platforms, cannot be themed, and do not scale with the user text-size '
            'setting. Use an Icon from the Material set plus a real label, via '
            'StatusBadge / StatusTag in lib/widgets/app_widgets.dart.\n'
            '${violations.join('\n')}',
      );
    });

    test('no emoji in the user-facing translation strings', () {
      // The emoji sweep above already covers lib/services/localization_service.dart.
      // This asserts it explicitly so that a future refactor which moves the maps
      // into their own file cannot quietly stop scanning the strings the user sees.
      const path = 'lib/services/localization_service.dart';
      final source = File(path).readAsStringSync();
      expect(
        emojiPattern.hasMatch(source),
        isFalse,
        reason: '$path is user-facing copy and must stay emoji-free',
      );
    });
  });

  group('gradient policy', () {
    test('no gradient painters in lib/', () {
      final violations = <String>[];

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (gradientPattern.hasMatch(lines[i])) {
            violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Use flat fills, a hairline border, or a translucent scrim '
            '(ImageScrim) instead of a gradient. Gradients were the main source '
            'of the decorative look: they varied in contrast across the '
            'surfaces they covered and read as a shadow that was never '
            'designed.\n${violations.join('\n')}',
      );
    });
  });

  group('semantic colour usage', () {
    test('status colours come from the theme, not a literal', () {
      // The badge chain used to hardcode Colors.red[100] / Colors.purple[900],
      // which meant it silently ignored dark mode. This asserts the new widgets
      // resolve colour through the AppColors extension instead.
      const widgets = 'lib/widgets/app_widgets.dart';
      final widgetSource = File(widgets).readAsStringSync();

      // app_widgets.dart resolves every status colour through context.colors.
      expect(
        RegExp(
          r'Colors\.(red|purple|green|blue|orange)\[',
        ).hasMatch(widgetSource),
        isFalse,
        reason: '$widgets must not hardcode indexed Material colour ramps',
      );
      expect(widgetSource, contains('context.colors'));

      // The extension that backs it is declared alongside the palette itself.
      const theme = 'lib/theme/app_theme.dart';
      final themeSource = File(theme).readAsStringSync();
      expect(themeSource, contains('extension AppColorsContext'));
      expect(themeSource, contains('Theme.of(this).extension<AppColors>()!'));
    });

    test('AppColors exposes every status tone the UI can render', () {
      const theme = 'lib/theme/app_theme.dart';
      final source = File(theme).readAsStringSync();

      for (final field in const [
        'urgent',
        'verified',
        'pending',
        'resolved',
        'adultMissing',
        'onStatus',
        'borderSubtle',
        'surfaceMuted',
        'imageScrim',
      ]) {
        expect(
          source,
          contains('final Color $field;'),
          reason: 'missing $field',
        );
      }
    });
  });

  group('motion policy', () {
    test('motion tokens are non-zero and ordered', () {
      const motion = 'lib/theme/app_motion.dart';
      final source = File(motion).readAsStringSync();

      const expected = {
        'instant': 120,
        'fast': 200,
        'normal': 320,
        'slow': 460,
      };

      for (final entry in expected.entries) {
        expect(
          source,
          contains('${entry.key} = Duration(milliseconds: ${entry.value})'),
          reason: '${entry.key} should be ${entry.value}ms',
        );
      }

      // Ascending durations: a "fast" token slower than "slow" would make the
      // whole motion system read as random.
      expect(
        expected.values.toList(),
        orderedEquals([...expected.values]..sort()),
      );
    });

    test('entrance animation cancels its delay timer on dispose', () {
      // FadeSlideIn schedules a Timer for staggered entries. A ListView can
      // recycle a child before the timer fires, and a surviving timer would
      // call setState on a disposed State. Asserting the cancellation is
      // present keeps that regression from coming back with a refactor.
      const motion = 'lib/theme/app_motion.dart';
      final source = File(motion).readAsStringSync();

      expect(source, contains("import 'dart:async';"));
      expect(source, contains('_timer?.cancel();'));
      expect(
        RegExp(r'if \(mounted\)\s*_controller\.forward\(\);').hasMatch(source),
        isTrue,
        reason: 'the timer must check mounted before forwarding',
      );
    });
  });
}
