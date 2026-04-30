import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/catalog_state.dart';
import 'state/download_state.dart';
import 'state/settings_state.dart';
import 'ui/home_page.dart';

/// The entry point of the Flutter application.
/// 
/// We must call [WidgetsFlutterBinding.ensureInitialized] before using
/// any plugin that requires the Flutter engine (like SharedPreferences),
/// otherwise async calls made during initialization will fail silently.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsState()),
        ChangeNotifierProvider(create: (context) => CatalogState()),
        ChangeNotifierProvider(create: (context) => DownloadState()),
      ],
      child: const MusicCatalogApp(),
    ),
  );
}

/// The root widget of the Music Catalog application.
class MusicCatalogApp extends StatelessWidget {
  const MusicCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurpleAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}
