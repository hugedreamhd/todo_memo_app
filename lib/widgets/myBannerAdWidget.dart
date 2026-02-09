import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class MyBannerAdWidget extends StatefulWidget {
  const MyBannerAdWidget({Key? key}) : super(key: key);

  @override
  State<MyBannerAdWidget> createState() => _MyBannerAdWidgetState();
}

class _MyBannerAdWidgetState extends State<MyBannerAdWidget> {
  @override
  void initState() {
    super.initState();
    // build가 완료된 후 첫 프레임에서 광고를 호출하도록 유도합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadAd();
      });
    });
  }

  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  // 테스트 광고 ID (안드로이드 공식 테스트 ID)
  final String _adUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   _loadAd(); // Context를 사용할 수 있는 시점에 광고 로드
  // }

  Future<void> _loadAd() async {
    if (_isLoading || _isLoaded) return;
    _isLoading = true;

    // 1. 현재 화면 너비에 맞는 적응형 사이즈 계산
    final AdSize size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate(),
        ) ??
        AdSize.banner;

    if (!mounted) return;

    // 2. 배너 광고 객체 생성
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("✅ 광고 로드 성공!");
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          // 계획서에 따른 상세 로그 출력 (403 에러 디버깅용)
          debugPrint("❌ 광고 로드 실패: $error");
          debugPrint("❌ 에러 상세 정보: ${error.responseInfo}");
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _isLoading = false;
            });
          }
        },
      ),
    );

    // 3. 광고 호출
    await _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // 메모리 누수 방지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 광고가 로드되었을 때만 위젯 표시
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // 로드 전에는 비어있는 박스 (또는 로딩 인디케이터)
    return const SizedBox.shrink();
  }
}
