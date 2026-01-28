import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/hazard_provider.dart';
import 'providers/location_provider.dart';

void main() {
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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
