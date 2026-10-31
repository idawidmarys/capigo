import 'dart:io' show Platform;
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/tracking_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  // Enable DevicePreview on Web/browser preview, but automatically disable on physical iOS device
  final bool enableDevicePreview = kIsWeb || (!kReleaseMode && !Platform.isIOS);

  runApp(
    DevicePreview(
      enabled: enableDevicePreview,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()..init()),
          ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ],
        child: const CapiGoApp(),
      ),
    ),
  );
}

class CapiGoApp extends StatelessWidget {
  const CapiGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final locale = Locale(userProvider.languageCode);

    return MaterialApp(
      title: 'CapiGo',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context) ?? locale,
      builder: DevicePreview.appBuilder,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl', ''),
        Locale('en', ''),
        Locale('de', ''),
        Locale('es', ''),
      ],
      theme: AppTheme.lightTheme,
      home: userProvider.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : userProvider.isOnboardingCompleted
              ? const HomeScreen()
              : OnboardingScreen(
                  onFinished: () {
                    // Handled inside UserProvider
                  },
                ),
    );
  }
}
