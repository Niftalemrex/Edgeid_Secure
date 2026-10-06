import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_setup.dart';
import 'verification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const EdgeIDDemo());
}

class EdgeIDDemo extends StatelessWidget {
  const EdgeIDDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdgeID-Secure Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const VerificationScreen(),
    );
  }
}