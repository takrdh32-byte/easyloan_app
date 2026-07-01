import 'package:flutter/material.dart';
import 'clonelab_bridge.dart';

void main() {
  runApp(const CloneLabApp());
}

class CloneLabApp extends StatelessWidget {
  const CloneLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloneLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        primaryColor: const Color(0xFF6C63FF),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'Engine Ready';

  Future<void> _checkEngine() async {
    try {
      final version = await CloneLabBridge.getEngineVersion();
      setState(() => _status = version);
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _cloneWhatsApp() async {
    setState(() => _status = 'Cloning...');
    try {
      final pid = await CloneLabBridge.createClone(appPackage: 'com.whatsapp');
      setState(() => _status = 'Clone PID: $pid');
    } catch (e) {
      setState(() => _status = 'Clone failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.copy, size: 64, color: Color(0xFF6C63FF)),
            const SizedBox(height: 24),
            const Text('CloneLab', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkEngine,
              child: const Text('Check Engine'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cloneWhatsApp,
              child: const Text('Clone WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}