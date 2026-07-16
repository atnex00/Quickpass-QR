import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/supervisor_provider.dart';
import 'screens/admin/admin_panel.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/employee/dashboard_screen.dart';
import 'screens/employee/leave_history_screen.dart';
import 'screens/security/scanner_screen.dart';
import 'screens/supervisor/supervisor_dashboard.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  apiService.init();

  // Firebase init happens inside NotificationService.init()
  // called from _QuickpassAppState._initNotifications()

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final settings = SettingsProvider();
  await settings.load();

  final auth = AuthProvider(api: apiService);

  runApp(QuickpassApp(
    apiService: apiService,
    settings: settings,
    auth: auth,
  ));
}

class QuickpassApp extends StatefulWidget {
  const QuickpassApp({
    super.key,
    required this.apiService,
    required this.settings,
    required this.auth,
  });
  final ApiService apiService;
  final SettingsProvider settings;
  final AuthProvider auth;

  @override
  State<QuickpassApp> createState() => _QuickpassAppState();
}

class _QuickpassAppState extends State<QuickpassApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.apiService.onForceLogout = _handleForceLogout;
    widget.auth.onLoggedOut = _handleForceLogout;
    widget.auth.onLoggedIn = _handleLoginSuccess;
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService().init(
      navigatorKey: _navigatorKey,
      apiService: widget.apiService,
    );

    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    widget.auth.addListener(_checkPendingNotification);
    _checkPendingNotification();
  }

  void _checkPendingNotification() {
    if (!widget.auth.isAuthenticated || widget.auth.isLoading) return;
    final pending = NotificationService().consumePendingScreen();
    if (pending == null) return;
    Widget screen;
    switch (pending) {
      case 'new_request':
        screen = const SupervisorDashboard();
        break;
      case 'approved':
      case 'rejected':
      case 'revoked':
      case 'out_scan':
      case 'in_scan':
        screen = const LeaveHistoryScreen();
        break;
      default:
        screen = const EmployeeDashboard();
    }
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
    widget.auth.removeListener(_checkPendingNotification);
  }

  void _handleForceLogout() {
    _resetProviders();
    widget.auth.clearAuth();
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _resetProviders() {
    final context = _navigatorKey.currentState?.context;
    if (context == null) return;
    try {
      context.read<LeaveProvider>().reset();
    } catch (_) {
      debugPrint('LeaveProvider reset failed (already disposed)');
    }
    try {
      context.read<SupervisorProvider>().reset();
    } catch (_) {
      debugPrint('SupervisorProvider reset failed (already disposed)');
    }
    try {
      context.read<ScanProvider>().reset();
    } catch (_) {
      debugPrint('ScanProvider reset failed (already disposed)');
    }  }

  void _handleLoginSuccess() {
    _resetProviders();
    final home = widget.auth.isAdmin
        ? const AdminPanel()
        : widget.auth.isSupervisor
            ? const SupervisorDashboard()
            : widget.auth.isScanner
                ? const ScannerScreen()
                : const EmployeeDashboard();
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => home),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.apiService;
    return Provider<ApiService>.value(
      value: api,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: widget.settings),
          ChangeNotifierProvider.value(value: widget.auth),
          ChangeNotifierProvider(create: (_) => LeaveProvider(api: api)),
          ChangeNotifierProvider(create: (_) => SupervisorProvider(api: api)),
          ChangeNotifierProvider(create: (_) => ScanProvider(api: api)),
        ],
        child: Consumer2<AuthProvider, SettingsProvider>(
          builder: (context, auth, settings, _) {
            return MaterialApp(
              navigatorKey: _navigatorKey,
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              theme: QuickpassTheme.light,
              darkTheme: QuickpassTheme.dark,
              themeMode: settings.themeMode,
              home: _buildHome(auth),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (auth.isLoading) {
      return const SplashScreen();
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (auth.user == null) {
      return const LoginScreen();
    }

    if (auth.isAdmin) {
      return const AdminPanel();
    }

    if (auth.isSupervisor) {
      return const SupervisorDashboard();
    }

    if (auth.isScanner) {
      return const ScannerScreen();
    }

    return const EmployeeDashboard();
  }
}
