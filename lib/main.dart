import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:my_tool_shed/pages/dashboard_page.dart';
import 'package:my_tool_shed/pages/login_page.dart';
import 'package:my_tool_shed/services/auth_service.dart';
import 'package:my_tool_shed/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Assuming flutterfire configure generates this
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:io';
//import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:my_tool_shed/utils/logger.dart';

final _logger = Logger('MyToolShed');

Future<void> loadEnvFile() async {
  try {
    _logger.info('Starting environment file loading process...');
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
        _logger.info('Attempting to load .env from: $location');
        await dotenv.load(fileName: location);
        _logger.info('Successfully loaded .env from: $location');
        loaded = true;
        break;
      } catch (e) {
        _logger
            .warning('Failed to load .env from: $location - ${e.toString()}');
      }
    }

    if (!loaded) {
      _logger.warning('No .env file found. Using default values.');
      // Set default values for required environment variables
      dotenv.env['FIREBASE_PROJECT_ID'] = 'my-tool-shed-8565f';
      dotenv.env['FIREBASE_STORAGE_BUCKET'] =
          'my-tool-shed-8565f.firebasestorage.app';
    }

    // Log the loaded environment variables (without sensitive values)
    _logger.info('Environment variables loaded. Checking required variables:');
    final requiredVars = [
      'FIREBASE_API_KEY_ANDROID',
      'FIREBASE_APP_ID_ANDROID',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_STORAGE_BUCKET'
    ];

    for (final varName in requiredVars) {
      final isSet = dotenv.env[varName]?.isNotEmpty ?? false;
      _logger.info('$varName: ${isSet ? 'Set' : 'Not set'}');
      if (!isSet) {
        _logger.warning('Required environment variable $varName is not set!');
      }
    }
  } catch (e, stackTrace) {
    _logger.severe('Error loading environment file', e, stackTrace);
    rethrow;
  }
}

void main() async {
  try {
    _logger.info('Starting app initialization...');
    WidgetsFlutterBinding.ensureInitialized();
    _logger.info('Flutter binding initialized');

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
    _logger.info('Logging configured');

    // Load environment variables
    _logger.info('Attempting to load environment variables...');
    await loadEnvFile();
    _logger.info('Environment variables loaded');

    // Initialize the Mobile Ads SDK
    _logger.info('Initializing Mobile Ads SDK...');
    try {
      await MobileAds.instance.initialize();
      _logger.info('Mobile Ads SDK initialized');
    } catch (e, stackTrace) {
      _logger.warning('Failed to initialize Mobile Ads SDK', e, stackTrace);
      // Continue without ads
    }

    // Initialize notifications
    _logger.info('Initializing notifications...');
    try {
      await NotificationService().init();
      _logger.info('Notifications initialized');
    } catch (e, stackTrace) {
      _logger.warning('Failed to initialize notifications', e, stackTrace);
      // Continue without notifications
    }

    _logger.info('Initializing Firebase...');
    try {
      _logger.info('Loading Firebase options...');
      final options = DefaultFirebaseOptions.currentPlatform;
      _logger.info('Firebase options loaded: ${options.projectId}');

      _logger.info('Initializing Firebase app...');
      await Firebase.initializeApp(
        options: options,
      );
      _logger.info('Firebase initialized successfully');

      // Verify Firebase services
      _logger.info('Verifying Firebase services...');
      try {
        final auth = FirebaseAuth.instance;
        _logger.info('Firebase Auth initialized');

        final firestore = FirebaseFirestore.instance;
        _logger.info('Firebase Firestore initialized');

        final storage = FirebaseStorage.instance;
        _logger.info('Firebase Storage initialized');
      } catch (e, stackTrace) {
        _logger.warning(
            'Failed to initialize some Firebase services', e, stackTrace);
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize Firebase', e, stackTrace);
      if (e.toString().contains('duplicate-app')) {
        _logger.info('Firebase already initialized, continuing...');
      } else {
        rethrow;
      }
    }

    _logger.info('Initializing AppLogger...');
    AppLogger.init();
    _logger.info('AppLogger initialized');

    _logger.info('Running app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    _logger.severe('Fatal error during app initialization', e, stackTrace);
    rethrow;
  }
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
