import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/hazard_provider.dart';
import 'providers/location_provider.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env missing or not bundled (e.g. first clone); env vars will be null
  }
  await Firebase.initializeApp();
  await SupabaseService.initialize();
  runApp(const VisionRoadApp());
}

class VisionRoadApp extends StatelessWidget {
  const VisionRoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HazardProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}


// temporary page
/*
import 'package:flutter/material.dart';
import 'screens/popup_preview_page.dart'; // Import your preview page

void main() {
  runApp(const VisionRoadApp());
}

class VisionRoadApp extends StatelessWidget {
  const VisionRoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PopupPreviewPage(), // TEMPORARY preview
    );
  }
} 
*/