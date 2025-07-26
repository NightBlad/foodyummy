import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/recipe_management_screen.dart';
import 'screens/ingredient_management_screen.dart';
import 'screens/admin_statistics_screen.dart';
import 'screens/admin_settings_screen.dart';

class AppSettings extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 16;

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;

  AppSettings() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 16;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setDouble('fontSize', _fontSize);
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setFontSize(double value) {
    _fontSize = value;
    _saveToPrefs();
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(create: (_) => AppSettings(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    return MaterialApp(
      title: 'FoodyYummy - Ứng dụng nấu ăn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: appSettings.isDarkMode ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFFFF6B6B),
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: appSettings.isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFFF6B6B),
          foregroundColor: appSettings.isDarkMode ? Colors.white : Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: appSettings.isDarkMode
            ? Colors.grey[900]
            : const Color(0xFFF8F9FA),
        cardColor: appSettings.isDarkMode ? Colors.grey[850] : Colors.white,
        canvasColor: appSettings.isDarkMode ? Colors.grey[900] : Colors.white,
        dialogTheme: DialogThemeData(
          backgroundColor: appSettings.isDarkMode
              ? Colors.grey[850]
              : Colors.white,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: appSettings.isDarkMode
              ? Colors.red[200]
              : const Color(0xFFFF6B6B),
          unselectedLabelColor: appSettings.isDarkMode
              ? Colors.grey[400]
              : Colors.grey,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return RecipeScreen();
          }
          return LoginScreen();
        },
      ),
      routes: {
        '/user-management': (context) => const UserManagementScreen(),
        '/recipe-management': (context) => const RecipeManagementScreen(),
        '/ingredient-management': (context) =>
            const IngredientManagementScreen(),
        '/admin-statistics': (context) => const AdminStatisticsScreen(),
        '/admin-settings': (context) => const AdminSettingsScreen(),
      },
    );
  }
}

class CustomZoomPageTransitionsBuilder extends PageTransitionsBuilder {
  final Duration duration;
  const CustomZoomPageTransitionsBuilder({
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ZoomPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
      duration: duration,
    );
  }
}

class ZoomPageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final Duration duration;

  const ZoomPageTransition({
    Key? key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    required this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        final double scale = 0.95 + (curvedAnimation.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: curvedAnimation.value, child: child),
        );
      },
      child: child,
    );
  }
}
