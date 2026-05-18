import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _baseUrl = 'https://thejacoco.com.au';
const _homeUrl = '$_baseUrl/';

const _tabs = <AppTab>[
  AppTab(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    url: _homeUrl,
  ),
  AppTab(
    label: 'Shop',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
    url: '$_baseUrl/shop/',
  ),
  AppTab(
    label: 'Contact',
    icon: Icons.contact_page_outlined,
    selectedIcon: Icons.contact_page_rounded,
    url: '$_baseUrl/contact-us/contact-us/',
  ),
  AppTab(
    label: 'Wishlist',
    icon: Icons.favorite_border_rounded,
    selectedIcon: Icons.favorite_rounded,
    url: '$_baseUrl/wishlist/',
  ),
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ThejaCocoApp());
}

class ThejaCocoApp extends StatelessWidget {
  const ThejaCocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theja Coco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F7A4A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const ThejaCocoWebApp(),
    );
  }
}

class ThejaCocoWebApp extends StatefulWidget {
  const ThejaCocoWebApp({super.key});

  @override
  State<ThejaCocoWebApp> createState() => _ThejaCocoWebAppState();
}

class _ThejaCocoWebAppState extends State<ThejaCocoWebApp> {
  WebViewController? _controller;

  bool get _supportsWebView {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  bool _hasLoadError = false;
  bool _isLoading = true;
  bool _isGoingBack = false;
  int _progress = 0;
  String _currentPageUrl = _homeUrl;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (!_supportsWebView) {
      _isLoading = false;
      return;
    }
    _controller = _buildController();
    _loadHomePage();
  }

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
              _isLoading = !_isGoingBack && progress < 100;
            });
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _currentPageUrl = url;
              _selectTab(_tabIndexForUrl(url));
              _hasLoadError = false;
              _isLoading = !_isGoingBack;
              _progress = 0;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isGoingBack = false;
              _isLoading = false;
              _progress = 100;
            });
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null || !mounted) return;
            setState(() {
              _currentPageUrl = url;
              _selectTab(_tabIndexForUrl(url));
            });
          },
          onWebResourceError: (error) {
            if (!_isMainPageError(error) || !mounted) return;
            setState(() {
              _hasLoadError = true;
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  bool _isMainPageError(WebResourceError error) {
    if (error.isForMainFrame == true) return true;
    if (error.isForMainFrame == false) return false;

    final errorUrl = error.url;
    if (errorUrl == null || errorUrl.isEmpty) return false;
    return Uri.tryParse(errorUrl)?.replace(fragment: '') ==
        Uri.tryParse(_currentPageUrl)?.replace(fragment: '');
  }

  int _tabIndexForUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '/';
    final normalizedPath = path.endsWith('/') ? path : '$path/';

    for (var index = 1; index < _tabs.length; index++) {
      final tabPath = Uri.parse(_tabs[index].url).path;
      if (normalizedPath.startsWith(tabPath)) {
        return index;
      }
    }

    return 0;
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
  }

  Future<void> _openTab(int index) async {
    if (index == _selectedTabIndex && !_hasLoadError) return;
    if (!mounted) return;

    setState(() {
      _selectTab(index);
      _currentPageUrl = _tabs[index].url;
      _hasLoadError = false;
      _isLoading = true;
      _progress = 0;
    });

    await _controller?.loadRequest(Uri.parse(_tabs[index].url));
  }

  Future<void> _loadHomePage() async {
    setState(() {
      _hasLoadError = false;
      _isLoading = true;
      _progress = 0;
    });

    await _controller?.loadRequest(Uri.parse(_homeUrl));
  }

  Future<void> _reload() async {
    if (!mounted) return;

    setState(() {
      _hasLoadError = false;
      _isLoading = true;
      _progress = 0;
    });

    await _controller?.reload();
  }

  Future<void> _handleBack() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      if (mounted) {
        setState(() {
          _isGoingBack = true;
          _isLoading = false;
        });
      }
      await controller.goBack();
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final showNativeError = _hasLoadError;
    final controller = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!_supportsWebView) const UnsupportedPlatformView(),
              if (_supportsWebView && !showNativeError && controller != null)
                WebViewWidget(controller: controller),
              if (_isLoading && !showNativeError)
                AppLoadingView(progress: _progress),
              if (_supportsWebView && showNativeError)
                AppNetworkErrorView(onRetry: _reload),
            ],
          ),
        ),
        bottomNavigationBar: _supportsWebView
            ? AppBottomNavigationBar(
                selectedIndex: _selectedTabIndex,
                onDestinationSelected: _openTab,
              )
            : null,
      ),
    );
  }
}

class AppTab {
  const AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String url;
}

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3ECE6))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          height: 68,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDDF3E6),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.icon, color: const Color(0xFF587165)),
                selectedIcon: Icon(
                  tab.selectedIcon,
                  color: const Color(0xFF0F7A4A),
                ),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

class UnsupportedPlatformView extends StatelessWidget {
  const UnsupportedPlatformView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'This app WebView runs on Android and iOS. Please run it on a mobile emulator or device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF173B2B),
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final visibleProgress = progress.clamp(8, 100) / 100;

    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Theja Coco',
                style: TextStyle(
                  color: Color(0xFF173B2B),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: visibleProgress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE8EFEA),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF0F7A4A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppNetworkErrorView extends StatelessWidget {
  const AppNetworkErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFF0F7A4A),
              size: 56,
            ),
            const SizedBox(height: 22),
            const Text(
              'No internet connection',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF173B2B),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please check your network and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64766D),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F7A4A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
