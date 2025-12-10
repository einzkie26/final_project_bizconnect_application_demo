import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'controllers/admin_controller.dart';
import 'controllers/preferences_controller.dart';
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(preferencesControllerProvider).darkMode;
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bizconnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dialogBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('admins').doc(currentUser.uid).get(),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (adminSnapshot.hasData && adminSnapshot.data!.exists) {
                  return const AdminDashboard();
                }
                
                return const MainNavigation();
              },
            );
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
