import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:baromemo/main_screen.dart';
import 'package:baromemo/repositories/todo_repository.dart';
import 'package:baromemo/services/local_notification_service.dart';
import 'package:baromemo/viewmodels/todo_view_model.dart';
import 'package:baromemo/viewmodels/onboarding_view_model.dart';
import 'package:baromemo/theme/app_theme.dart';

/// 홈 위젯에서 "메모 추가하기" 버튼 탭 여부를 Flutter 전역에서 감지하는 notifier
final ValueNotifier<bool> quickAddNotifier = ValueNotifier(false);

/// 홈 위젯에서 특정 메모 아이템을 탭했을 때 열어야 할 todo id
final ValueNotifier<String?> openTodoIdNotifier = ValueNotifier(null);

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (kDebugMode) print('Widget Background Callback: $uri');
  if (uri?.scheme == 'myappwidget' && uri?.host == 'togglecompletion') {
    final todoId = uri?.pathSegments.first;
    if (todoId != null) {
      final repository = TodoRepository();
      var todos = await repository.loadTodos();
      final index = todos.indexWhere((item) => item.id == todoId);
      if (index != -1) {
        todos[index] = todos[index].copyWith(
          isCompleted: !todos[index].isCompleted,
        );
        await repository.saveTodos(todos);
      }
    }
  }
}

void main() async {
  // 1. Flutter 프레임워크와 네이티브 엔진 연결 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 로컬 알림 서비스 초기화
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // 3. 구글 모바일 광고 SDK 초기화
  await MobileAds.instance.initialize();

  // 4. 홈 위젯 백그라운드 콜백 등록
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  // 5. 위젯 MethodChannel 등록 — Android 위젯에서 QUICK_ADD / OPEN_TODO 수신 시 notifier 활성화
  const widgetChannel = MethodChannel('com.belyself.baromemo/widget');
  widgetChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'quickAdd':
        quickAddNotifier.value = true;
        break;
      case 'openTodo':
        final todoId = call.arguments as String?;
        if (todoId != null) {
          openTodoIdNotifier.value = todoId;
        }
        break;
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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notificationService.requestPermissions();
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final vm = TodoViewModel(
              TodoRepository(),
              widget.notificationService,
            )..initialize();
            HomeWidget.widgetClicked.listen((uri) {
              if (uri?.scheme == 'myappwidget' &&
                  uri?.host == 'togglecompletion') {
                vm.initialize(syncWidget: false);
              }
            });
            return vm;
          },
        ),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
      ],
      child: MaterialApp(
        title: '바로메모',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primary,
            brightness: Brightness.light,
            surface: Colors.white,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primary,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: _themeMode,
        home: MainScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
      ),
    );
  }
}
