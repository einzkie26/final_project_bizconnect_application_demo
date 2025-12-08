import 'package:flutter/material.dart';
import 'package:final_project_bizconnect_application_demo/navigate/home.dart';
import 'package:final_project_bizconnect_application_demo/navigate/messages.dart';
import 'package:final_project_bizconnect_application_demo/navigate/search_index.dart';
import 'package:final_project_bizconnect_application_demo/navigate/profile.dart';
import 'package:final_project_bizconnect_application_demo/navigate/preferences.dart';
import 'package:final_project_bizconnect_application_demo/widgets/navigation_bar/navigateBar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomePage(),
    const MessagesPage(),
    const SearchPage(),
    const ProfilePage(),
    const PreferencesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}