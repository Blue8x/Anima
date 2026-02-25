# Contributing to Anima

Thank you for your interest in contributing to Anima! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/anima.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Commit: `git commit -am 'Add your feature'`
6. Push to the branch: `git push origin feature/your-feature`
7. Submit a Pull Request

## Development Setup

### Backend (Rust)

```bash
cd frontend/rust
cargo check
cargo build
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter test
```

## Code Standards

### Rust
- Use `cargo fmt` for formatting
- Use `cargo clippy` for linting
- Write tests for new functionality
- Document public APIs with doc comments

### Flutter/Dart
- Use `dart format` for formatting
- Use `flutter analyze` for linting
- Follow Effective Dart guidelines
- Write tests for new functionality

## Commit Message Guidelines

- Use clear, descriptive commit messages
- Start with a verb (Add, Fix, Update, Remove, etc.)
- Keep messages concise but informative
- Reference issues when applicable: "Fix #123"

## Areas for Contribution

- **Backend**: LLM integration, embedding generation, optimization
- **Frontend**: UI improvements, accessibility, platform-specific features
- **Documentation**: Guides, tutorials, API documentation
- **Testing**: Unit tests, integration tests, performance tests
- **Performance**: Optimization, battery impact reduction

## Reporting Issues

- Use clear, descriptive titles
- Include steps to reproduce
- Provide system information (OS, device, app version)
- Attach logs or error messages
- Include screenshots/videos if applicable

## Code Review Process

1. Automated checks (tests, linting) must pass
2. At least one maintainer review required
3. Feedback will be provided for any changes needed
4. Once approved, changes will be merged

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue or discussion for questions about contributing.

