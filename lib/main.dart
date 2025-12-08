import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'controllers/admin_controller.dart';
import 'login/login_acc.dart';
import 'login/register_acc.dart';
import 'admin/admin_dashboard.dart';
import 'admin/users_table.dart';
import 'admin/reports_page.dart';
import 'admin/admin_settings.dart';
import 'navigate/main_navigation.dart';
import 'debug_user.dart';
import 'test_map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final adminController = AdminController();
  await adminController.createAdminIfNotExists();
  
  FlutterError.onError = (details) {
    if (!details.toString().contains('ChromeProxyService')) {
      FlutterError.presentError(details);
    }
  };
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bizconnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Force check current user to prevent cached sessions
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && snapshot.hasData) {
            return const MainNavigation();
          }
          
          return const LoginScreen();
        },
      ),
      routes: {
        '/register': (context) => const LoginRegisterPage(),

        '/admin/dashboard': (context) => const AdminDashboard(),
        '/admin/users': (context) => const UsersTablePage(),
        '/admin/reports': (context) => const ReportsPage(),
        '/admin/settings': (context) => const AdminSettings(),
        '/debug': (context) => const DebugUserPage(),
        '/test-map': (context) => const TestMapPage(),
      },
    );
  }
}
