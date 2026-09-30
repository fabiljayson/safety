import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      title: 'Safety',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
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
