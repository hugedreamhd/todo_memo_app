import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:todolist/main_screen.dart';
import 'package:todolist/repositories/todo_repository.dart';
import 'package:todolist/services/local_notification_service.dart';
import 'package:todolist/viewmodels/todo_view_model.dart';

/// 홈 위젯에서 "메모 추가하기" 버튼 탭 여부를 Flutter 전역에서 감지하는 notifier
final ValueNotifier<bool> quickAddNotifier = ValueNotifier(false);

void main() async {
  // 1. Flutter 프레임워크와 네이티브 엔진 연결 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 로컬 알림 서비스 초기화
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // 3. 구글 모바일 광고 SDK 초기화
  await MobileAds.instance.initialize();

  // 4. 위젯 MethodChannel 등록 — Android 위젯에서 QUICK_ADD 수신 시 notifier 활성화
  const widgetChannel = MethodChannel('com.perungi.todolist/widget');
  widgetChannel.setMethodCallHandler((call) async {
    if (call.method == 'quickAdd') {
      quickAddNotifier.value = true;
    }
  });

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
    // 스플래시 최소 1.5초 표시
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
