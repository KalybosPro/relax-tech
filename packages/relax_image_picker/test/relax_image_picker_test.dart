import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:relax_image_picker/relax_image_picker.dart';

void main() {
  test('package can be imported', () {
    // Test that the package can be imported without errors
    expect(RelaxImagePicker, isNotNull);
  });

  test('models can be instantiated', () {
    final imageFile = RelaxImageFile(
      id: 'test',
      path: '/test/path.jpg',
      mimeType: 'image/jpeg',
      size: 1024,
      width: 100,
      height: 100,
    );

    expect(imageFile.id, 'test');
    expect(imageFile.path, '/test/path.jpg');
    expect(imageFile.mimeType, 'image/jpeg');
    expect(imageFile.size, 1024);
  });

  test('camera-first is opt-in', () {
    const sheet = InAppGalleryPickerSheet(
      theme: RelaxPickerTheme(),
      title: 'title',
      confirmButtonText: 'confirm',
      cancelButtonText: 'cancel',
      validateButtonText: 'validate',
      galleryTabText: 'gallery',
      cameraTabText: 'camera',
      documentsTabText: 'documents',
    );

    expect(sheet.cameraFirst, isFalse);
  });

  testWidgets('asset tile builder is told whether selection mode is on', (
    tester,
  ) async {
    bool? receivedSelectionMode;

    final theme = RelaxPickerTheme(
      assetTileBuilder:
          (
            context, {
            required asset,
            required selected,
            required selectionMode,
            required selectionIndex,
            required isVideo,
            required videoDuration,
            required thumbnail,
            required onTap,
            required onLongPress,
          }) {
            receivedSelectionMode = selectionMode;
            return thumbnail;
          },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => theme.assetTileBuilder!(
            context,
            asset: AssetEntity(id: '1', typeInt: 1, width: 1, height: 1),
            selected: false,
            selectionMode: true,
            selectionIndex: 0,
            isVideo: false,
            videoDuration: Duration.zero,
            thumbnail: const SizedBox(key: Key('thumbnail')),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(receivedSelectionMode, isTrue);
    expect(find.byKey(const Key('thumbnail')), findsOneWidget);
  });
}
