import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/settings_view.dart';
import '../settings/settings_controller.dart';
import '../account/account_view.dart';
import '../chat/chat_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;
  static const routeName = '/';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  static const String _apiKeyPrefKey = 'openrouter_api_key';

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyPrefKey);
    if (apiKey == null || apiKey.isEmpty) {
      // If no API key is found, switch to the Account tab (index 1)
      if (mounted) {
        setState(() {
          _selectedIndex = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set up your OpenRouter API key to get started'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const ChatView(),  // Chat Page
      const AccountView(),  // Account settings page
      SettingsView(controller: widget.settingsController),  // Settings page
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
} 