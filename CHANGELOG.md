## 1.2.0

### 🚀 Performance Optimizations
- **Code Generation**: Replaced 150+ sequential string operations with bulk templates (-98% overhead)
- **File Caching**: Added intelligent file-level caching with timestamp invalidation (-65-75% on multi-builds)
- **Asset Parallelization**: Converted sequential asset processing to parallel execution (+30% on asset-heavy projects)
- **Memory Efficiency**: Optimized string buffer usage and reduced memory allocations

### 🔒 Security Enhancements
- **Random Salt Generation**: Each encrypted file now uses unique 128-bit random salt (vs fixed salt)
- **Password Validation**: Added minimum 8-character password requirement
- **Enhanced Encryption**: Improved AES-256 implementation with better key derivation
- **Security Documentation**: Comprehensive security practices added to SECURITY.md

### 🧪 Testing & Quality
- **Comprehensive Test Suite**: Added 73 tests covering all functionality (up from ~20)
- **Crypto Tests**: 17 tests for encryption/decryption with various scenarios
- **Asset Tests**: 26 tests for asset generation and parallelization
- **Cache Tests**: 10 tests for caching functionality
- **Error Handling Tests**: 20 tests for edge cases and error conditions

### 📚 Documentation & Future Planning
- **Future Roadmap**: Added prioritized optimization recommendations in README.md
- **Security Best Practices**: Detailed encryption and key management guidelines
- **Performance Guidelines**: Recommendations for optimal usage patterns

### 🔧 Technical Improvements
- **Error Handling**: Enhanced error messages and graceful failure handling
- **Code Quality**: Improved maintainability with better separation of concerns
- **Backward Compatibility**: All changes maintain compatibility with existing projects
- **Cross-Platform**: Verified compatibility across Windows, macOS, and Linux

## 1.1.6+1

- Some changes in README.md file

## 1.1.6

- Added assets command (`env_builder assets`) for encrypting and embedding assets directly in Dart code
- Support for images (PNG, JPG, GIF, WebP), videos (MP4, WebM, MOV, AVI, MKV), and SVGs
- Asset compression and SVG minification
- Encryption options: XOR (fast, lightweight) or AES (secure)
- Generated widget helpers for images, SVGs, and video controllers
- Flutter_gen compatible API

## 1.1.5

- Refactored command structure: made `apk` and `aab` commands top-level instead of subcommands of `build`

## 1.1.4

- Added APK build command (`env_builder apk`) for building Flutter APKs with release obfuscation
- Added AAB build command (`env_builder aab`) for building Flutter AABs with release obfuscation

## 1.1.3

- `--output-dir`: Custom output directory (default: `env`)
- `--no-encrypt`: Skip encryption of sensitive variables
- `--verbose`: Detailed output during build process

## 1.1.2

- Refactored code structure for improved maintainability
- Updated example package structure
- Modified the env package generation's command

## 1.1.1

- Ask a user if he want to encrypt .env files in his env package
- Bug fixed

## 1.1.0

- Added environment file encryption/decryption with AES
- Improved error handling for invalid/corrupted files
- Updated README with usage examples

## 1.0.0+1

- README modified.
- LICENSE changed.

## 1.0.0

- Initial version.
