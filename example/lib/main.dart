import 'package:flutter/material.dart';
import 'package:relax_image_picker/relax_image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relax Image Picker Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RelaxPickerResult? _result;

  Future<void> _pickMedia() async {
    final result = await RelaxImagePicker.pick(
      context,
      allowImages: true,
      allowVideos: true,
      allowDocuments: true,
      enableCamera: true,
      enablePreview: true,
      maxSelection: 10,
      enableCompression: false,
    );

    if (mounted) {
      setState(() {
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relax Image Picker Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            ElevatedButton(
              onPressed: _pickMedia,
              child: const Text('Sélectionner des médias'),
            ),
            const SizedBox(height: 32),
            if (_result != null) ...[
              Text('Médias sélectionnés: ${_result!.files.length}'),
              Text('Images: ${_result!.images.length}'),
              Text('Vidéos: ${_result!.videos.length}'),
              Text('Documents: ${_result!.documents.length}'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _result!.files.length,
                  itemBuilder: (context, index) {
                    final file = _result!.files[index];
                    return ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(file.path.split('/').last),
                      subtitle: Text('${file.mimeType} - ${file.size} bytes'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
