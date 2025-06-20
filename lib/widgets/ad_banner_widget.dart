import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/logger.dart';

class AdBannerWidget extends StatefulWidget {
  final String adUnitId;
  final EdgeInsets? padding;
  final Alignment alignment;

  const AdBannerWidget({
    super.key,
    required this.adUnitId,
    this.padding,
    this.alignment = Alignment.centerLeft,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    if (!mounted) return;

    try {
      final initializationStatus = await MobileAds.instance.initialize();
      AppLogger.info('Mobile Ads SDK initialized: $initializationStatus');

      if (mounted) {
        setState(() {
          _isAdInitialized = true;
        });
        _initBannerAd();
      }
    } catch (e) {
      AppLogger.error('Error initializing MobileAds', e, null);
      if (mounted) {
        setState(() {
          _isAdInitialized = false;
        });
      }
    }
  }

  void _initBannerAd() {
    if (!mounted || !_isAdInitialized) return;

    try {
      _disposeAd(); // Clean up any existing ad

      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            AppLogger.info('Ad loaded successfully');
            _bannerAd = ad as BannerAd;
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            AppLogger.error('Ad failed to load', error, null);
            ad.dispose();
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
              });
            }
          },
          onAdOpened: (ad) => AppLogger.info('Ad opened'),
          onAdClosed: (ad) => AppLogger.info('Ad closed'),
          onAdImpression: (ad) => AppLogger.info('Ad impression'),
          onAdClicked: (ad) => AppLogger.info('Ad clicked'),
        ),
      );

      _bannerAd?.load();
    } catch (e) {
      AppLogger.error('Error initializing ad', e, null);
      _disposeAd();
    }
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) {
      setState(() {
        _isAdLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdInitialized || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: widget.padding ??
              const EdgeInsets.only(right: 20.0, bottom: 125.0),
          child: Container(
            alignment: widget.alignment,
            height: _bannerAd?.size.height.toDouble(),
            width: _bannerAd?.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      ),
    );
  }
}
