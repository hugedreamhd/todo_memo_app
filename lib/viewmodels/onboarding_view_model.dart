import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:baromemo/widgets/showcase_keys.dart';

class OnboardingViewModel extends ChangeNotifier {
  static const String _keyShowGuide = 'show_guide_v2'; // 새로운 버전의 가이드 키
  bool _shouldShowGuide = false;

  bool get shouldShowGuide => _shouldShowGuide;

  OnboardingViewModel() {
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    _shouldShowGuide = prefs.getBool(_keyShowGuide) ?? true;
    notifyListeners();
  }

  Future<void> completeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowGuide, false);
    _shouldShowGuide = false;
    notifyListeners();
  }

  void startGuide(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([
      ShowcaseKeys.searchKey,
      ShowcaseKeys.tagKey,
      ShowcaseKeys.importantMemoKey,
      ShowcaseKeys.trashKey,
      ShowcaseKeys.darkModeKey,
      ShowcaseKeys.addMemoKey,
    ]);
  }
}
