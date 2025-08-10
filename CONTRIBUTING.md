# Contributing to ZenDevToolkit

First off, thank you for considering contributing to ZenDevToolkit! It's people like you that make ZenDevToolkit such a great tool for the developer community.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps to reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed and what behavior you expected**
* **Include screenshots if possible**
* **Include your macOS version and Xcode version**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a detailed description of the suggested enhancement**
* **Provide specific examples to demonstrate the enhancement**
* **Describe the current behavior and expected behavior**
* **Explain why this enhancement would be useful**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure your code follows the existing code style
4. Make sure your code lints (we'll add SwiftLint soon)
5. Issue that pull request!

## Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/zen-dev-toolkit.git
   cd zen-dev-toolkit
   ```

2. **Open in Xcode**
   ```bash
   open ZenDevToolkit.xcodeproj
   ```

3. **Build and Run**
   - Select your Mac as the target
   - Press ⌘+R to build and run

## Coding Guidelines

### Swift Style Guide

We follow the [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide) with these key points:

* **Naming**: Use descriptive names with camel case for functions, variables, and constants
* **Spacing**: Use 4 spaces for indentation (Xcode default)
* **Comments**: Write self-documenting code, add comments only when necessary
* **SwiftUI**: Follow SwiftUI best practices and conventions
* **Force Unwrapping**: Avoid force unwrapping, use guard or if-let instead

### Git Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification. Please read our [Commit Convention Guide](COMMIT_CONVENTION.md) for detailed information.

**Quick Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Example:**
```
feat(base64): add encoding and decoding functionality

Implement Base64 encoder/decoder with support for both text input
and file processing. Includes error handling for invalid input.

Closes #12
```

**Types:** feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

See [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md) for full details.

### Code Organization

* Keep related functionality in the same file
* Separate UI components into their own views
* Use extensions to organize code logically
* Follow MVVM pattern where appropriate

## Testing

* Write unit tests for new functionality
* Ensure all tests pass before submitting PR
* Test on both light and dark mode
* Test window resizing behavior

## Documentation

* Update README.md if you change functionality
* Add inline documentation for complex functions
* Update CHANGELOG.md with your changes

## Adding New Tools

When adding a new developer tool:

1. Create a new View in `ContentView.swift` or a separate file
2. Add the tool to the tab selector
3. Implement the core functionality
4. Add keyboard shortcuts where appropriate
5. Include paste/copy functionality
6. Add appropriate error handling
7. Test thoroughly
8. Update README with the new feature

## Questions?

Feel free to open an issue with the tag "question" if you have any questions about contributing.

## Recognition

Contributors will be recognized in our README. Thank you for your contributions!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.