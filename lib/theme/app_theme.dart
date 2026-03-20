import 'package:flutter/material.dart';

class AppColors {
  // 메인 테마 색상
  static const Color primary = Color(0xFF81ECE1);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // 텍스트 관련
  static const Color text = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575); // 보통 회색 계열

  // 기능성 컬러 (정확한 8자리)
  static const Color pointGreen = Color(0xFF58D68D); // 추가 버튼
  static const Color pointBlue = Color(0xFF4C6EF5); // 저장 버튼
  static const Color importantYellow = Color(0xFFFFD54F); // 중요/별
  static const Color warningRed = Color(0xFFFF5C5C); // 삭제/경고
  static const Color widgetAlert = Color(0xFF1976D2); //위젯 알림
}

class AppTheme {
  static Color get widgetAlert => AppColors.widgetAlert;
  static Color get primary => AppColors.primary;
  static Color get background => AppColors.background;
  static Color get surface => AppColors.surface;

  // 텍스트 관련
  static Color get text => AppColors.text;
  static Color get textSecondary => AppColors.textSecondary;

  // 기능성 컬러 (정확한 8자리)
  static Color get pointGreen => AppColors.pointGreen; // 추가 버튼
  static Color get pointBlue => AppColors.pointBlue; // 저장 버튼
  static Color get importantYellow => AppColors.importantYellow; // 중요/별
  static Color get warningRed => AppColors.warningRed; // 삭제/경고

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Pretendard',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Pretendard',
    );
  }
}
