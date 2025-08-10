# Security Policy

## Supported Versions

Currently supporting the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

1. **DO NOT** open a public issue on GitHub
2. Email your findings to dilee.dev@gmail.com with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Resolution Timeline**: Depends on severity
  - Critical: 1-2 weeks
  - High: 2-4 weeks
  - Medium: 4-8 weeks
  - Low: Next release cycle

## Security Best Practices

This application follows these security principles:

### Data Privacy
- All processing happens locally on your Mac
- No data is sent to external servers
- No analytics or tracking
- No network requests except for update checks (future feature)

### Code Security
- No execution of user input as code
- Input validation on all text fields
- Secure clipboard handling
- Sandboxed application (when distributed via Mac App Store)

### Dependencies
- Minimal external dependencies
- Regular security audits of dependencies
- Swift-native implementations preferred

## Security Features

- **Local Processing**: All tools run locally without internet connection
- **No Data Storage**: Tools don't persist sensitive data
- **Clipboard Security**: Clipboard access only when explicitly requested by user
- **macOS Security**: Follows Apple's security best practices

## Contact

For security concerns, please contact:
- Email: dilee.dev@gmail.com
- GitHub: [@dilee](https://github.com/dilee)

## Acknowledgments

Thanks to the security researchers who help keep ZenDevToolkit secure.