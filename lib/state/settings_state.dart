import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends ChangeNotifier {
  String _slskdUrl = 'http://YOUR_SLSKD_HOST:5030';
  String _username = '';
  String _password = '';
  String _searchEngine = 'iTunes';

  String get slskdUrl => _slskdUrl;
  String get username => _username;
  String get password => _password;
  String get searchEngine => _searchEngine;

  SettingsState();

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _slskdUrl = prefs.getString('slskdUrl') ?? 'http://YOUR_SLSKD_HOST:5030';
    _username = prefs.getString('slskdUsername') ?? '';
    _password = prefs.getString('slskdPassword') ?? '';
    _searchEngine = prefs.getString('searchEngine') ?? 'iTunes';
  }

  Future<void> saveSettings(
    String url,
    String user,
    String pass,
    String searchEngine,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slskdUrl', url);
    await prefs.setString('slskdUsername', user);
    await prefs.setString('slskdPassword', pass);
    await prefs.setString('searchEngine', searchEngine);
    
    _slskdUrl = url;
    _username = user;
    _password = pass;
    _searchEngine = searchEngine;
    notifyListeners();
  }
}
