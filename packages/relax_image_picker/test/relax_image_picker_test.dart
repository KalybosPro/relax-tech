import 'package:flutter_test/flutter_test.dart';

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
}
