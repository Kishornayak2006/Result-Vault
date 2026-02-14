import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/year_selection_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ResultVaultApp());
}

class ResultVaultApp extends StatelessWidget {
  const ResultVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      // 🌞 LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // 🌙 DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // 🚦 STARTUP ROUTER (IMPORTANT)
      home: const StartUpRouter(),
    );
  }
}

/// 🧠 Decides which screen to show on app launch
class StartUpRouter extends StatelessWidget {
  const StartUpRouter({super.key});

  Future<int?> _getSavedYears() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('course_years'); // ✅ single source of truth
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _getSavedYears(),
      builder: (context, snapshot) {
        // ⏳ Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🆕 First launch → ask years
        if (!snapshot.hasData) {
          return const YearSelectionScreen();
        }

        // ✅ Years already selected
        return const HomeScreen();
      },
    );
  }
}
