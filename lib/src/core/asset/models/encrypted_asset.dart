/// Asset encryption result
class EncryptedAsset {

  EncryptedAsset({
    required this.key,
    required this.data,
    required this.hash,
  });
  final List<int> key;
  final List<int> data;
  final String hash;
}
