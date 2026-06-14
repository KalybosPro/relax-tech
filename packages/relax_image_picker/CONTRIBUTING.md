# Contribution

Thank you for contributing to `relax_image_picker`! This document explains best practices, the contribution workflow, and instructions for developers who want to help improve the project.

## Getting Started

1. Fork the repository and clone your fork.
2. Create a dedicated branch for your work:

```bash
git checkout -b feat/my-change
```

3. Make sure your target branch is up to date with `main`.

## Development Setup

This Flutter package supports mobile and desktop platforms for local development.

### Prerequisites

- Stable Flutter installed
- Dart SDK compatible with the package
- `flutter`, `dart`, and `git` tools available

### Install dependencies

In the package root:

```bash
flutter pub get
```

In the example app:

```bash
cd example
flutter pub get
```

## Project Structure

- `lib/`: public API and presentation logic
- `lib/src/controllers/`: controllers and application state
- `lib/src/models/`: data models and result objects
- `lib/src/services/`: platform integrations and technical services
- `lib/src/widgets/`: reusable UI components
- `example/`: demo app and validation
- `test/`: package unit tests

## Development Workflow

### General rules

- Prefer small, focused commits.
- Explain the purpose of each PR clearly.
- Follow Dart/Flutter style guidelines.
- Add or update tests for any significant feature or bug fix.

### Formatting

Use Dart formatting before submitting changes:

```bash
flutter format .
```

### Static analysis

Run lint checks to verify code quality:

```bash
flutter analyze
```

### Tests

To run the package unit tests:

```bash
flutter test
```

To run the example app tests:

```bash
cd example
flutter test
```

## Manual Validation

1. Run the example app on an emulator or device:

```bash
cd example
flutter run
```

2. Verify image, video, and document pickers work correctly.
3. Test camera capture if enabled.
4. Validate Android/iOS permission behavior.

## Code Contributions

### Feature requests

- Open an issue describing the need and user scenario.
- Provide an example of expected usage if possible.

### Bug fixes

- Open an issue with the current behavior and expected result.
- Include clear reproduction steps.
- Suggest a fix if you have one.

### Pull requests

1. Base your PR on the `main` branch.
2. Provide a clear title and detailed description.
3. List the main changes and expected impact.
4. Add screenshots or GIFs if the UI is affected.
5. Mention whether the change requires a version bump or changelog update.

## Best Practices

- Follow idiomatic Flutter and Dart conventions.
- Avoid introducing unnecessary dependencies.
- Document public components and important parameters.
- Preserve compatibility with supported platforms.

## Debugging

- Use `flutter run` to open the example and test interactively.
- Use `flutter analyze` to catch static issues.
- If you modify native code, verify Android/iOS builds.

## Versioning

For major changes, indicate whether a version bump is needed in the changelog or PR title.

## License

By contributing to this project, you agree that your code will be published under the repository's MIT license.

---

Thank you again for your contribution! Every improvement is welcome and helps make `relax_image_picker` more stable and complete.