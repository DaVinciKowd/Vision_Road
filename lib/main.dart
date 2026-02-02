import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const VisionRoadApp());
}

class VisionRoadApp extends StatelessWidget {
  const VisionRoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
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

