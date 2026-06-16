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

  /// Default look — no theme passed.
  Future<void> _pickDefault() async {
    final result = await RelaxImagePicker.pick(
      context,
      maxSelection: 10,
      accentColor: const Color(0xFF25D366),
    );
    _store(result);
  }

  /// Fully customized: theme styling + several widget-slot builders.
  Future<void> _pickCustom() async {
    final result = await RelaxImagePicker.pick(
      context,
      maxSelection: 10,
      title: 'Mes fichiers',
      galleryTabText: 'Photos',
      documentsTabText: 'Docs',
      theme: _customTheme(),
    );
    _store(result);
  }

  void _store(RelaxPickerResult result) {
    if (mounted) setState(() => _result = result);
  }

  // ---------------------------------------------------------------------------
  // A custom theme mixing style overrides and full widget builders.
  // ---------------------------------------------------------------------------

  RelaxPickerTheme _customTheme() {
    const accent = Color(0xFF6C4DF6);

    return RelaxPickerTheme(
      // --- Plain styling ---
      accentColor: accent,
      sheetBorderRadius: 32,
      tileBorderRadius: 18,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: .w800,
        color: accent,
      ),
      noDocumentsLabel: 'Aucun fichier pour le moment',
      maxSelectionLabelBuilder: (max) => 'Tu ne peux en choisir que $max 🙂',

      // --- Full widget overrides (builders) ---

      // Circular send button with a count bubble.
      sendButtonBuilder: (
        context, {
        required selectedCount,
        required processing,
        required onSend,
      }) {
        return FilledButton(
          onPressed: onSend,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            shape: const StadiumBorder(),
            padding: const .symmetric(horizontal: 20, vertical: 14),
          ),
          child: processing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text('Envoyer ($selectedCount)'),
        );
      },

      // Text cancel button.
      cancelButtonBuilder: (context, {required label, required onPressed}) {
        return TextButton(
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        );
      },

      // Segmented-style tab.
      tabBuilder: (
        context, {
        required label,
        required icon,
        required selected,
        required onTap,
      }) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const .symmetric(horizontal: 4),
            padding: const .symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? accent : accent.withValues(alpha: 0.08),
              borderRadius: .circular(14),
            ),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                Icon(icon,
                    size: 18, color: selected ? Colors.white : accent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : accent,
                    fontWeight: .w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },

      // Browse button.
      browseButtonBuilder: (
        context, {
        required label,
        required icon,
        required onPressed,
      }) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(backgroundColor: accent),
            icon: Icon(icon),
            label: Text(label),
          ),
        );
      },

      // Camera tile.
      cameraTileBuilder: (context, {required onTap}) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.6)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.add_a_photo, color: Colors.white, size: 30),
            ),
          ),
        );
      },

      // Custom document card reusing the ready-made thumbnail.
      documentTileBuilder: (
        context, {
        required document,
        required selected,
        required thumbnail,
        required onTap,
      }) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: .circular(18),
              color: selected
                  ? accent.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.08),
              border: .all(
                color: selected ? accent : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const .all(8),
            child: Column(
              children: [
                Expanded(child: Center(child: thumbnail)),
                const SizedBox(height: 6),
                Text(
                  document.fileName,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: accent, size: 18),
              ],
            ),
          ),
        );
      },

      // Empty documents state.
      emptyDocumentsBuilder: (context) {
        return const Center(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              Icon(Icons.inbox_rounded, size: 72, color: accent),
              SizedBox(height: 12),
              Text('Rien ici — touche « Parcourir »'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relax Image Picker Demo')),
      body: Padding(
        padding: const .all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDefault,
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Défaut'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickCustom,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Thème + builders'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_result != null) ...[
              Align(
                alignment: .centerLeft,
                child: Text(
                  'Sélection : ${_result!.files.length} '
                  '(${_result!.images.length} images, '
                  '${_result!.videos.length} vidéos, '
                  '${_result!.documents.length} documents)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _result!.files.length,
                  itemBuilder: (context, index) {
                    final file = _result!.files[index];
                    return ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(file.path.split('/').last),
                      subtitle: Text('${file.mimeType} · ${file.size} bytes'),
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
