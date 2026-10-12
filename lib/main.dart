import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LaundroMaticApp());
}

class LaundroMaticApp extends StatelessWidget {
  const LaundroMaticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LAUNDROMATIC',
          themeMode: themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E64D4),
              primary: const Color(0xFF1E64D4),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F8FC),
            cardColor: Colors.white,
            dividerColor: const Color(0xFFF1F5F9),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F8FC),
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              primary: const Color(0xFF3B82F6),
              surface: const Color(0xFF1E293B),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            cardColor: const Color(0xFF1E293B),
            dividerColor: const Color(0xFF334155),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              foregroundColor: Color(0xFFF8FAFC),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF1E293B),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}