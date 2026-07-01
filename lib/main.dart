import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const _channel = MethodChannel('com.clonelab.app/native');

  Future<void> _checkEngine() async {
    // पहले तुरंत डायलॉग दिखाओ ताकि पता चले बटन ने काम किया
    _showMessage("Button pressed, calling native...");

    try {
      final version = await _channel.invokeMethod<String>('getEngineVersion');
      if (!mounted) return;
      _showMessage("Engine version: $version");
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    }
  }

  Future<void> _cloneWhatsApp() async {
    _showMessage("Cloning WhatsApp...");

    try {
      final pid = await _channel.invokeMethod<int>('createClone', {'package': 'com.whatsapp'});
      if (!mounted) return;
      _showMessage("Clone PID: $pid");
    } catch (e) {
      _showMessage("Clone error: ${e.toString()}");
    }
  }

  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CloneLab'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
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