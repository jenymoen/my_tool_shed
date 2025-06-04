import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:my_tool_shed/pages/dashboard_page.dart';
import 'package:my_tool_shed/pages/login_page.dart';
import 'package:my_tool_shed/services/auth_service.dart';
import 'package:my_tool_shed/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Assuming flutterfire configure generates this
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:io';
//import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

final _logger = Logger('MyToolShed');

Future<void> loadEnvFile() async {
  try {
    // Try multiple possible locations for the .env file
    final locations = [
      '.env', // Root directory
      'assets/.env', // Assets directory
      '../.env', // Parent directory
      'android/app/.env', // Android app directory
    ];

    bool loaded = false;
    for (final location in locations) {
      try {
        _logger.info('Trying to load .env from: $location');
        await dotenv.load(fileName: location);
        _logger.info('Successfully loaded .env from: $location');
        loaded = true;
        break;
      } catch (e) {
        _logger.info('Failed to load .env from: $location');
      }
    }

    if (loaded) {
      // Log the loaded environment variables (without sensitive values)
      _logger.info('Loaded environment variables:');
      _logger.info(
          'FIREBASE_API_KEY_ANDROID: ${dotenv.env['FIREBASE_API_KEY_ANDROID']?.isNotEmpty ?? false ? 'Set' : 'Not set'}');
      _logger.info(
          'FIREBASE_APP_ID_ANDROID: ${dotenv.env['FIREBASE_APP_ID_ANDROID']?.isNotEmpty ?? false ? 'Set' : 'Not set'}');
      _logger.info(
          'FIREBASE_MESSAGING_SENDER_ID: ${dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.isNotEmpty ?? false ? 'Set' : 'Not set'}');
      _logger.info(
          'FIREBASE_PROJECT_ID: ${dotenv.env['FIREBASE_PROJECT_ID']?.isNotEmpty ?? false ? 'Set' : 'Not set'}');
      _logger.info(
          'FIREBASE_STORAGE_BUCKET: ${dotenv.env['FIREBASE_STORAGE_BUCKET']?.isNotEmpty ?? false ? 'Set' : 'Not set'}');
    } else {
      _logger.warning('Failed to load .env file from any location');
    }
  } catch (e) {
    _logger.severe('Error loading environment file', e);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack trace: ${record.stackTrace}');
    }
  });

  // Load environment variables
  await loadEnvFile();

  // Initialize the Mobile Ads SDK
  await MobileAds.instance.initialize();

  // Initialize notifications
  await NotificationService().init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // App already initialized, continue
      _logger.info('Firebase already initialized, continuing...');
    } else {
      // Re-throw if it's a different error
      _logger.severe('Failed to initialize Firebase', e);
      rethrow;
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale');
    if (savedLocale != null) {
      setState(() {
        _locale = Locale(savedLocale);
      });
    }
  }

  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Tool Shed',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('no'), // Norwegian
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in
            return DashboardPage(
              onLocaleChanged: (locale) {
                setState(() {
                  _locale = locale;
                });
              },
            );
          }
          // User is not logged in
          return const LoginPage();
        },
      ),
    );
  }
}
