import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/supervisor_provider.dart';
import 'providers/scan_provider.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/employee/dashboard_screen.dart';
import 'screens/supervisor/supervisor_dashboard.dart';
import 'screens/admin/admin_panel.dart';
import 'screens/security/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  apiService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(QuickpassApp(apiService: apiService));
}

class QuickpassApp extends StatefulWidget {
  final ApiService apiService;
  const QuickpassApp({super.key, required this.apiService});

  @override
  State<QuickpassApp> createState() => _QuickpassAppState();
}

class _QuickpassAppState extends State<QuickpassApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/icon/app-icon.png'), context);
      precacheImage(const AssetImage('assets/icon/logo.png'), context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.apiService;
    return Provider<ApiService>.value(
      value: api,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
          ChangeNotifierProvider(create: (_) => LeaveProvider(api: api)),
          ChangeNotifierProvider(create: (_) => SupervisorProvider(api: api)),
          ChangeNotifierProvider(create: (_) => ScanProvider(api: api)),
        ],
        child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: QuickpassTheme.light,
            darkTheme: QuickpassTheme.dark,
            home: _buildHome(auth),
          );
        },
      ),
      ),
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (auth.isLoading) {
      return const LoginScreen();
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
