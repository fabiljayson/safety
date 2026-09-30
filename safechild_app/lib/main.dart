import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // package:intl throws LocaleDataException for any locale whose date symbols
  // have not been loaded, and flutter_localizations does not load them. Needed
  // for DateFormat.yMMMd() in AppTranslations.missingSince().
  for (final locale in _supportedLocales) {
    await initializeDateFormatting(locale.languageCode);
  }

  // Firebase is optional: without the native config files the app must still
  // start, just without push notifications.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
      "Firebase initialization failed: $e. Notifications will not work.",
    );
  }

  runApp(const ProviderScope(child: SafetyApp()));
}

const List<Locale> _supportedLocales = [Locale('en'), Locale('fr')];

class SafetyApp extends ConsumerStatefulWidget {
  const SafetyApp({super.key});

  @override
  ConsumerState<SafetyApp> createState() => _SafetyAppState();
}

class _SafetyAppState extends ConsumerState<SafetyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      // Built from the provider's locale rather than AppTranslations.of(context):
      // this runs above the Localizations widget MaterialApp creates, so there is
      // no Localizations ancestor to read yet.
      title: AppTranslations(locale).translate('title'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: _supportedLocales,
      // English is the fallback, so an unsupported device language never
      // renders the raw translation keys.
      localeResolutionCallback: (deviceLocale, supported) {
        return deviceLocale != null &&
                supported.any(
                  (l) => l.languageCode == deviceLocale.languageCode,
                )
            ? deviceLocale
            : const Locale('en');
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.when(
        data: (user) =>
            user == null ? const AuthScreen() : const MainNavigationScreen(),
        loading: () =>
            const AuthScreen(), // Keep AuthScreen to show its own loading indicator
        error: (_, _) => const AuthScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
