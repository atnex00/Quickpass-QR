import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/supervisor_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/settings_provider.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/employee/dashboard_screen.dart';
import 'screens/supervisor/supervisor_dashboard.dart';
import 'screens/admin/admin_panel.dart';
import 'screens/security/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  apiService.init();

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
  final ApiService apiService;
  final SettingsProvider settings;
  final AuthProvider auth;
  const QuickpassApp({
    super.key,
    required this.apiService,
    required this.settings,
    required this.auth,
  });

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
  }

  void _handleForceLogout() {
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _handleLoginSuccess() {
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
