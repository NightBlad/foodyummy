import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/utf8_config.dart';
import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/app_initializer.dart';
import 'screens/user_management_screen.dart';
import 'screens/recipe_management_screen.dart';
import 'screens/ingredient_management_screen.dart';
import 'screens/admin_statistics_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'services/notification_service.dart';
import 'services/notification_handler.dart';
import 'services/auto_notification_service.dart';

// Hàm xử lý thông báo khi app ở background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');

  // Có thể lưu thông báo vào local storage để hiển thị khi user mở app
}

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

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppSettings(),
      child: const FoodYummyApp(),
    ),
  );
}

class FoodYummyApp extends StatefulWidget {
  const FoodYummyApp({super.key});

  @override
  State<FoodYummyApp> createState() => _FoodYummyAppState();
}

class _FoodYummyAppState extends State<FoodYummyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  // Setup notifications khi app khởi động
  Future<void> _setupNotifications() async {
    // Initialize notification service
    await NotificationService().initialize();

    // Initialize auto notification service
    final autoNotificationService = AutoNotificationService();
    await autoNotificationService.ensureTopicSubscription();
    autoNotificationService.startListening();

    // Handle notification khi app được mở từ terminated state
    await NotificationHandler.handleInitialMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        // Set context cho NotificationHandler
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationHandler.setContext(context);
        });

        return MaterialApp(
          title: 'FoodyYummy - Ứng dụng nấu ăn',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.red,
            primaryColor: const Color(0xFFFF6B6B),
            fontFamily: 'Roboto',
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: AppBarTheme(
              backgroundColor: settings.isDarkMode
                  ? Colors.grey[900]
                  : const Color(0xFFFF6B6B),
              foregroundColor: settings.isDarkMode ? Colors.white : Colors.white,
              elevation: 0,
            ),
            scaffoldBackgroundColor: settings.isDarkMode
                ? Colors.grey[900]
                : const Color(0xFFF8F9FA),
            cardColor: settings.isDarkMode ? Colors.grey[850] : Colors.white,
            canvasColor: settings.isDarkMode ? Colors.grey[900] : Colors.white,
            dialogTheme: DialogThemeData(
              backgroundColor: settings.isDarkMode
                  ? Colors.grey[850]
                  : Colors.white,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: settings.isDarkMode
                  ? Colors.red[200]
                  : const Color(0xFFFF6B6B),
              unselectedLabelColor: settings.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey,
            ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: settings.fontSize),
              bodyMedium: TextStyle(fontSize: settings.fontSize - 2),
            ),
          ),
          navigatorKey: GlobalKey<NavigatorState>(),
          home: Builder(
            builder: (context) {
              return StreamBuilder<User?>(
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
                    return const AppInitializer();
                  }
                  return const LoginScreen();
                },
              );
            },
          ),
          routes: {
            '/user-management': (context) => const UserManagementScreen(),
            '/recipe-management': (context) => const RecipeManagementScreen(),
            '/ingredient-management': (context) => const IngredientManagementScreen(),
            '/admin-statistics': (context) => const AdminStatisticsScreen(),
            '/admin-settings': (context) => const AdminSettingsScreen(),
          },
        );
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