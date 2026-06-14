# Contributing to relax_cli

Thank you for helping improve `relax_cli`! Contributions are welcome from everyone, whether you are filing an issue, suggesting a feature, or submitting a patch.

## How to Contribute

### Report a bug

1. Search existing issues to avoid duplicates.
2. Open a new issue with:
   - a clear description of the problem
   - the command you ran
   - your Dart/Flutter version
   - the expected behavior and actual behavior
   - any output or stack traces

### Request a feature

1. Describe the feature and the user problem it solves.
2. Explain the proposed behavior and any CLI changes.
3. If possible, include examples of the command syntax or generated output.

### Submit a fix or enhancement

1. Fork the repository.
2. Create a topic branch named clearly, e.g. `fix/create-command-output` or `feat/i18n-support`.
3. Make your changes in a small, focused commit.
4. Run tests and format code before submitting a pull request.
5. Open a pull request against the `main` branch with a clear description.

## Development Workflow

### Install dependencies

```bash
dart pub get
```

### Run tests

```bash
dart test
```

### Format code

```bash
dart format .
```

### Run locally

```bash
dart run bin/relax.dart create my_app -a bloc
```

## Code Guidelines

- Follow Dart idioms and existing project conventions.
- Keep CLI output clear and user-friendly.
- Prefer small, incremental changes.
- Ensure generated templates remain consistent across architectures.
- Update documentation and examples when behavior changes.

## Pull Request Checklist

- [ ] The change is small and focused.
- [ ] Code is formatted with `dart format`.
- [ ] Tests pass locally.
- [ ] The README or other docs are updated if needed.
- [ ] The PR description explains the problem and the solution.

## Communication

If you are unsure how to proceed, open an issue or comment on an existing one. Maintainers appreciate clarity and early discussion for larger changes.
