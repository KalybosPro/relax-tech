import 'package:flutter/material.dart';
import 'package:relax_storage/relax_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage engine once at app startup.
  await RelaxStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RelaxStorage Example',
      home: StorageDemo(),
    );
  }
}

class StorageDemo extends StatefulWidget {
  const StorageDemo({super.key});

  @override
  State<StorageDemo> createState() => _StorageDemoState();
}

class _StorageDemoState extends State<StorageDemo> {
  final RelaxStorage _storage = RelaxStorage('my-secret-key');
  String _output = 'Tap a button to try RelaxStorage.';

  Future<void> _saveData() async {
    await _storage.save<String>('username', 'john_doe');
    await _storage.save<int>('loginCount', 42);
    await _storage.save<bool>('isPremium', true);
    setState(() => _output = 'Data saved successfully!');
  }

  void _readData() {
    final username = _storage.read<String>('username');
    final count = _storage.read<int>('loginCount');
    final premium = _storage.read<bool>('isPremium');
    setState(() {
      _output =
          'username: $username\n'
          'loginCount: $count\n'
          'isPremium: $premium';
    });
  }

  Future<void> _deleteData() async {
    await _storage.delete('username');
    setState(() => _output = 'Deleted "username" key.');
  }

  Future<void> _clearAll() async {
    await _storage.clear();
    setState(() => _output = 'All data cleared.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RelaxStorage Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _saveData,
              child: const Text('Save Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _readData,
              child: const Text('Read Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _deleteData,
              child: const Text('Delete "username"'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _clearAll,
              child: const Text('Clear All'),
            ),
            const SizedBox(height: 24),
            Text(_output, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
