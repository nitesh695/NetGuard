# Contributing to NetGuard 🤝

Thank you for your interest in contributing to NetGuard! We welcome contributions from the community to help make this HTTP client even better.

## 🌟 Ways to Contribute

- 🐛 **Bug Reports**: Found a bug? Let us know!
- 💡 **Feature Requests**: Have an idea for a new feature?
- 📝 **Documentation**: Help improve our docs
- 💻 **Code Contributions**: Submit bug fixes or new features
- 🧪 **Testing**: Help us test on different platforms
- 💬 **Community Support**: Help others in discussions

## 🚀 Getting Started

### Prerequisites

Before contributing, make sure you have:

- Flutter SDK (latest stable version)
- Dart SDK 3.0.0 or higher
- Git
- A GitHub account
- Your favorite IDE (VS Code, Android Studio, IntelliJ)

### Setting Up Your Development Environment

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/NetGuard.git
   cd NetGuard
   ```

2. **Set up the upstream remote**
   ```bash
   git remote add upstream https://github.com/nitesh695/NetGuard.git
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run tests to ensure everything works**
   ```bash
   flutter test
   ```

5. **Run the example app**
   ```bash
   cd example
   flutter run
   ```

## 🐛 Reporting Bugs

When reporting bugs, please include:

### Bug Report Template

```markdown
## Bug Description
A clear and concise description of the bug.

## Steps to Reproduce
1. Configure NetGuard with...
2. Make a request to...
3. Observe the error...

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- NetGuard version: 
- Flutter version: 
- Dart version: 
- Platform: (iOS/Android/Web/Desktop)
- Device: (if mobile)

## Code Sample
```dart
// Minimal code sample that reproduces the issue
final netGuard = NetGuard();
// ...
```

## Additional Context
Any other relevant information, logs, or screenshots.
```

## 💡 Feature Requests

We love new ideas! When suggesting features:

1. **Check existing issues** to avoid duplicates
2. **Describe the use case** - why would this be useful?
3. **Provide examples** of how it might work
4. **Consider backwards compatibility**

### Feature Request Template

```markdown
## Feature Description
A clear description of the feature you'd like to see.

## Use Case
Why would this feature be useful? What problem does it solve?

## Proposed Implementation
How do you envision this working?

## Code Example
```dart
// Example of how this feature might be used
final netGuard = NetGuard();
await netGuard.newFeature();
```

## Alternatives Considered
Other approaches you've thought about.
```

## 💻 Code Contributions

### Before You Start

1. **Check existing issues** - someone might already be working on it
2. **Create an issue** if one doesn't exist for your contribution
3. **Discuss your approach** with maintainers before starting large changes

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes**
    - Write clean, documented code
    - Follow the existing code style
    - Add tests for new functionality
    - Update documentation as needed

3. **Test your changes**
   ```bash
   # Run all tests
   flutter test
   
   # Run tests with coverage
   flutter test --coverage
   
   # Test on different platforms
   flutter test -d chrome  # Web
   flutter test -d macos   # Desktop
   ```

4. **Update documentation**
    - Add/update code comments
    - Update README.md if needed
    - Add examples for new features

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new caching strategy"
   ```

### Commit Message Guidelines

We follow conventional commits format:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Adding/updating tests
- `chore:` - Build process or auxiliary tool changes

Examples:
```bash
git commit -m "feat: add request timeout configuration"
git commit -m "fix: resolve memory leak in cache manager"
git commit -m "docs: update authentication examples"
```

### Pull Request Process

1. **Update your branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push your changes**
   ```bash
   git push origin your-branch-name
   ```

3. **Create a Pull Request**
    - Use the PR template (see below)
    - Link related issues
    - Describe what you changed and why
    - Add screenshots for UI changes

### Pull Request Template

```markdown
## Description
Brief description of the changes.

## Related Issues
Fixes #123, Related to #456

## Type of Change
- [ ] Bug fix
- [ ] New feature  
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Added new feature X
- Fixed bug Y
- Updated documentation for Z

## Testing
- [ ] All tests pass
- [ ] Added tests for new functionality
- [ ] Tested on multiple platforms
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots or GIFs for UI changes.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code where necessary
- [ ] I have made corresponding changes to documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] All tests pass locally
```

## 🎨 Code Style Guidelines

### Dart Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` to format your code
- Use `dart analyze` to check for issues
- Maximum line length: 80 characters

### Documentation Style

- Use clear, concise language
- Include code examples for new features
- Update API documentation for public methods
- Use proper markdown formatting

### Example Code Style

```dart
/// Configures authentication for the NetGuard instance.
/// 
/// This method sets up automatic token refresh, logout handling,
/// and retry mechanisms for authenticated requests.
/// 
/// Example:
/// ```dart
/// netGuard.configureAuth(
///   callbacks: AdvanceAuthCallbacks(
///     initialToken: 'your_token',
///     onRefreshToken: () async => await refreshToken(),
///   ),
/// );
/// ```
void configureAuth({
  required AdvanceAuthCallbacks callbacks,
  AuthConfig config = const AuthConfig(),
}) {
  // Implementation...
}
```

## 🧪 Testing Guidelines

### Writing Tests

- Write unit tests for all public methods
- Test edge cases and error conditions
- Use descriptive test names
- Mock external dependencies

### Test Structure

```dart
group('NetGuard Authentication', () {
  late NetGuard netGuard;
  
  setUp(() {
    netGuard = NetGuard();
  });
  
  test('should configure auth with valid callbacks', () {
    // Arrange
    final callbacks = AdvanceAuthCallbacks(/* ... */);
    
    // Act
    netGuard.configureAuth(callbacks: callbacks);
    
    // Assert
    expect(netGuard.isAuthenticated(), isTrue);
  });
  
  test('should handle token refresh failure gracefully', () async {
    // Test implementation...
  });
});
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/netguard_test.dart

# Run with coverage
flutter test --coverage
lcov --summary coverage/lcov.info
```

## 📱 Platform-Specific Considerations

### Mobile (iOS/Android)
- Test network connectivity scenarios
- Verify background app handling
- Test with different screen sizes

### Web
- Ensure CORS compatibility
- Test with different browsers
- Verify service worker compatibility

### Desktop
- Test file system permissions
- Verify native HTTP client behavior
- Test window focus/blur scenarios

## 🔄 Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH` (e.g., 1.2.3)
- Breaking changes increment MAJOR
- New features increment MINOR
- Bug fixes increment PATCH

### Pre-release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version number is bumped
- [ ] Examples are updated
- [ ] Performance benchmarks run

## 🤝 Community Guidelines

### Code of Conduct

We are committed to providing a welcoming and inclusive environment:

- **Be respectful** - treat all contributors with respect
- **Be collaborative** - work together towards common goals
- **Be inclusive** - welcome newcomers and different perspectives
- **Be helpful** - assist others when possible
- **Be patient** - everyone learns at their own pace

### Communication

- Use GitHub issues for bug reports and feature requests
- Join discussions to help plan features
- Be constructive in code reviews
- Help answer questions from other users

## ❓ Getting Help

Need help contributing? Here's how to get support:

1. **Check the documentation** - README.md and API docs
2. **Search existing issues** - your question might be answered
3. **Create a discussion** - for general questions
4. **Join our community** - links in README.md

## 🏆 Recognition

Contributors are recognized in:
- CHANGELOG.md for each release
- README.md contributors section
- GitHub releases notes
- Social media shout-outs for significant contributions

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Testing Flutter Apps](https://docs.flutter.dev/testing)

---

Thank you for contributing to NetGuard! Together, we're building something amazing for the Flutter community. 🚀