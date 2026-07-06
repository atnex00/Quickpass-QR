import 'package:flutter/material.dart';
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
  runApp(QuickpassApp(apiService: apiService));
}

class QuickpassApp extends StatelessWidget {
  final ApiService apiService;
  const QuickpassApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Provider<ApiService>.value(
      value: apiService,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(api: apiService)),
          ChangeNotifierProvider(create: (_) => LeaveProvider(api: apiService)),
          ChangeNotifierProvider(create: (_) => SupervisorProvider(api: apiService)),
          ChangeNotifierProvider(create: (_) => ScanProvider(api: apiService)),
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
