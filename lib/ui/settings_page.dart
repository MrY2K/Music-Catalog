import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlController;
  late TextEditingController _userController;
  late TextEditingController _passController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsState>(context, listen: false);
    _urlController = TextEditingController(text: settings.slskdUrl);
    _userController = TextEditingController(text: settings.username);
    _passController = TextEditingController(text: settings.password);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final settings = Provider.of<SettingsState>(context, listen: false);
    settings.saveSettings(
      _urlController.text.trim(),
      _userController.text.trim(),
      _passController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Slskd Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC8202E)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://YOUR_SLSKD_HOST:5030',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Forgot your slskd password?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you are locked out, you can run "./slskd --reset-password" on your server, or edit the "slskd.yml" configuration file to reset your credentials to the defaults.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
