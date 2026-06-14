import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'asset.dart' as asset_reader;

/// Generator for assets.gen.dart file (flutter_gen style)
class AssetsGenGenerator {
  Future<String> generate() async {
    print('AssetsGenGenerator: Starting generation');
    // Use the actual file system path to find assets
    final assetsDir = p.join(Directory.current.path, 'assets');
    print('AssetsGenGenerator: Looking for assets in: $assetsDir');

    final assets = asset_reader.AssetReader.scanAssetsDirectory(assetsDir);
    print('AssetsGenGenerator: Found ${assets.length} assets');
    for (final asset in assets) {
      print(
        'AssetsGenGenerator: Asset: ${asset.path}, type: ${asset.type}, var: ${asset.variableName}',
      );
    }
    if (assets.isEmpty) {
      return '';
    }

    // Group assets by directory
    final assetGroups = _groupAssetsByDirectory(assets);
    print('AssetsGenGenerator: Asset groups: ${assetGroups.keys}');
    for (final entry in assetGroups.entries) {
      print(
        'AssetsGenGenerator: Group ${entry.key}: ${entry.value.map((a) => a.variableName)}',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('/// *****************************************************');
    buffer.writeln('///  EnvBuilder');
    buffer.writeln('/// *****************************************************');
    buffer.writeln();
    buffer.writeln('// coverage:ignore-file');
    buffer.writeln('// ignore_for_file: type=lint');
    buffer.writeln(
      '// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use',
    );
    buffer.writeln();
    buffer.writeln("import 'package:flutter/services.dart';");
    buffer.writeln("import 'package:flutter/widgets.dart';");
    buffer.writeln("import 'package:video_player/video_player.dart' as _video;");
    buffer.writeln("import 'package:flutter_svg/flutter_svg.dart' as _svg;");
    buffer.writeln(
      "import 'package:flutter_svg_provider/flutter_svg_provider.dart' as p;",
    );
    buffer.writeln(
      "import 'package:vector_graphics/vector_graphics_compat.dart' as _vgc;",
    );
    buffer.writeln();
    buffer.writeln("import 'assets.g.dart';");
    buffer.writeln();

    // Generate asset group classes
    final assetGroupClasses = <String>[];
    for (final entry in assetGroups.entries) {
      final groupName = entry.key;
      final groupAssets = entry.value;

      final className = '\$Assets${_capitalize(groupName)}Gen';
      assetGroupClasses.add(className);

      buffer.writeln('class $className {');
      buffer.writeln('  const $className();');
      buffer.writeln();

      final assetGetters = <String>[];
      for (final asset in groupAssets) {
        final getter = _generateAssetGetter(asset);
        buffer.writeln(getter);
        assetGetters.add(_getAssetReference(asset));
      }

      buffer.writeln();
      buffer.writeln('  /// List of all assets');
      buffer.write('  List<dynamic> get values => [');
      buffer.write(assetGetters.join(', '));
      buffer.writeln('];');
      buffer.writeln('}');
      buffer.writeln();
    }

    // Main Assets class
    buffer.writeln('class Assets {');
    buffer.writeln('  const Assets._();');
    buffer.writeln();
    buffer.writeln("  static const String package = 'app_assets';");
    buffer.writeln();

    for (final className in assetGroupClasses) {
      final fieldName = className
          .replaceFirst(r'$Assets', '')
          .replaceFirst('Gen', '')
          .toLowerCase();
      buffer.writeln('  static const $className $fieldName = $className();');
    }

    buffer.writeln('}');
    buffer.writeln();

    // AssetGenImage class
    _generateAssetGenImage(buffer);

    // SvgGenImage class
    _generateSvgGenImage(buffer);

    // VideoGenImage class
    _generateVideoGenImage(buffer);

    return buffer.toString();
  }

  Map<String, List<asset_reader.AssetFile>> _groupAssetsByDirectory(
    List<asset_reader.AssetFile> assets,
  ) {
    final groups = <String, List<asset_reader.AssetFile>>{};

    for (final asset in assets) {
      // Get relative path from assets directory
      final relativePath = p.relative(
        asset.path,
        from: p.join(Directory.current.path, 'assets'),
      );
      final parts = p.split(relativePath);

      // Use first directory level as group name, or 'misc' if no subdirectory
      final groupName = parts.length > 1
          ? _normalizeGroupName(parts[0])
          : 'misc';

      groups.putIfAbsent(groupName, () => []).add(asset);
    }

    return groups;
  }

  // Convert to PascalCase
  String _normalizeGroupName(String name) => name
        .split(RegExp(r'[\s_-]+'))
        .map(
          (part) => part.isEmpty
              ? ''
              : part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join('');

  String _capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  String _generateAssetGetter(asset_reader.AssetFile asset) {
    final relativePath = p.relative(
      asset.path,
      from: p.join(Directory.current.path, 'assets'),
    );
    final assetPath = 'assets/$relativePath';

    if (asset.type == asset_reader.AssetType.svg) {
      return '  /// File path: $assetPath\n  SvgGenImage get ${asset.variableName} => SvgGenImage(decrypted${asset.variableName});';
    } else if (asset.type == asset_reader.AssetType.video) {
      return '  /// File path: $assetPath\n  VideoGenImage get ${asset.variableName} => VideoGenImage(decrypted${asset.variableName});';
    } else {
      return '  /// File path: $assetPath\n  AssetGenImage get ${asset.variableName} => AssetGenImage(decrypted${asset.variableName});';
    }
  }

  String _getAssetReference(asset_reader.AssetFile asset) => asset.variableName;

  void _generateAssetGenImage(StringBuffer buffer) {
    buffer.write('''class AssetGenImage {
  const AssetGenImage(this._bytes, {this.size, this.flavors = const {}});

  final Uint8List _bytes;

  static const String package = 'app_assets';

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double scale= 1.0,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.memory(
      _bytes,
      key: key,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    double scale = 1.0,
  }) {
    return MemoryImage(_bytes, scale: scale);
  }

}

''');
  }

  void _generateSvgGenImage(StringBuffer buffer) {
    buffer.write(r'''class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}});

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}});

  final String _assetName;
  final Size? size;
  final Set<String> flavors;

  static const String package = 'app_assets';

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    Color? color,
    BlendMode colorBlendMode = BlendMode.srcIn,
    bool cacheColorFilter = false,
    Widget Function(BuildContext, Object, StackTrace)? errorBuilder,
    _svg.ColorMapper? colorMapper,
    _vgc.RenderingStrategy renderingStrategy = _vgc.RenderingStrategy.picture,
  }) {
    return _svg.SvgPicture.string(
      _assetName,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
      theme: theme,
      errorBuilder: errorBuilder,
      colorMapper: colorMapper,
      renderingStrategy: renderingStrategy,
    );
  }

  p.Svg get provider => p.Svg('${_assetName.hashCode}.svg',
      source: p.SvgSource.asset,
      svgGetter: (key) => Future.value(_assetName));
}
''');
  }

  void _generateVideoGenImage(StringBuffer buffer) {
    buffer.write('''class VideoGenImage {
  const VideoGenImage(this._bytes, {this.size, this.flavors = const {}});

  final Uint8List _bytes;
  final Size? size;
  final Set<String> flavors;

  static const String package = 'app_assets';

  Future<_video.VideoPlayerController> controller({
    _video.VideoPlayerOptions? videoPlayerOptions,
    Future<_video.ClosedCaptionFile>? closedCaptionFile,
    _video.VideoFormat? formatHint,
  }) async {
    final controller = _video.VideoPlayerController.memory(
      _bytes,
      videoPlayerOptions: videoPlayerOptions,
      closedCaptionFile: closedCaptionFile,
      formatHint: formatHint,
    );
    await controller.initialize();
    return controller;
  }

  Future<_video.VideoPlayer> video({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Widget? placeholder,
    Widget? errorBuilder,
    bool autoInitialize = true,
    double volume = 1.0,
    bool looping = false,
    bool showControls = false,
    bool showControlsOnInitialize = true,
    Duration? seek,
  }) async {
    final videoController = await controller();
    return _video.VideoPlayer(
      key: key,
      width: width,
      height: height,
      controller: videoController,
      fit: fit,
      alignment: alignment,
      placeholder: placeholder,
      errorBuilder: errorBuilder,
      autoInitialize: autoInitialize,
      volume: volume,
      looping: looping,
      showControls: showControls,
      showControlsOnInitialize: showControlsOnInitialize,
      seek: seek,
    );
  }
}
''');
  }
}
