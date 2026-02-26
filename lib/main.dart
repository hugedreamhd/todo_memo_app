import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:todolist/main_screen.dart';
import 'package:todolist/repositories/todo_repository.dart';
import 'package:todolist/services/local_notification_service.dart';
import 'package:todolist/viewmodels/todo_view_model.dart';

void main() async {
  // 1. Flutter 프레임워크와 네이티브 엔진 연결 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 로컬 알림 서비스 초기화
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // 3. 구글 모바일 광고 SDK 초기화
  await MobileAds.instance.initialize();

  // // 4. 테스트 디바이스 설정 (에뮬레이터 해결)
  // await MobileAds.instance.updateRequestConfiguration(
  //   RequestConfiguration(testDeviceIds: ['E19E03387BD77FBE4D1C68A4910C2641']),
  // );
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.notificationService});

  final LocalNotificationService notificationService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              TodoViewModel(TodoRepository(), widget.notificationService)
                ..initialize(),
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF81ECE1),
            brightness: Brightness.light,
            surface: Colors.white,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF81ECE1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: _themeMode,
        home: SplashScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    // Wait for at least 1.5 seconds to show the splash screen
    // or wait until the ViewModel is initialized.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => MainScreen(
              onToggleTheme: widget.onToggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('img/todays_todo.png', fit: BoxFit.cover),
          // Gradient overlay to ensure text/UI visibility if needed
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
