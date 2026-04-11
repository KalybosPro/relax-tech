# Security Policy

## Supported Versions

This Security Policy applies to the following versions of Env Builder CLI:

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: |
| 1.0.x   | :x:                |
| < 1.0   | :x:                |

We recommend using the latest version for the most secure experience.

## Reporting a Security Vulnerability

The Env Builder CLI team takes security seriously. If you believe you've found a security vulnerability, we encourage you to responsibly disclose it to us.

**Please do not report security vulnerabilities through public GitHub issues, discussions, or pull requests.**

### How to Report

1. Create a private advisory on GitHub (if you're a contributor with write access) or email the maintainers at [insert secure email here or use GitHub issues with clear marking].

2. Provide detailed information about the vulnerability:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes or mitigations

### When to Expect a Response

- **Acknowledgment**: Within 3 business days
- **Investigation**: We will investigate all legitimate reports and strive to respond within 7-10 days
- **Resolution**: We'll work on fixes and keep you updated on our progress

We kindly ask that you give us reasonable time to respond and address the issue before publicly disclosing it.

## Scope

This Security Policy is intended to cover Env Builder CLI itself and its core functionality including:

- Environment file parsing
- Package generation
- Encryption and decryption operations
- CLI command processing

This policy does not cover third-party dependencies. For vulnerabilities in dependencies like `encrypt` or `crypto`, please report them directly to the respective maintainers.

### Out of Scope

- Vulnerabilities in third-party packages or libraries
- Issues related to improper usage of the tool (e.g., committing .env files)
- General questions or feature requests

## Security Considerations for Users

As Env Builder CLI deals with sensitive environment data:

1. **Never commit sensitive data** to version control
2. **Use strong encryption keys** and rotate them regularly
3. **Limit access** to decryption keys to essential personnel only
4. **Verify checksums** when downloading the CLI binary
5. **Keep the tool updated** to benefit from security patches

## Encryption Security Practices

Env Builder CLI uses AES-256 encryption with the following security measures:

### ✅ Implemented Security Features

- **AES-256 Encryption**: Industry-standard symmetric encryption
- **Random Salt Generation**: Each file uses a unique random salt (128-bit)
- **Random IV**: Each encryption uses a unique initialization vector
- **SHA-256 Key Derivation**: Passwords are hashed with salt for key generation
- **Password Validation**: Minimum 8-character password requirement
- **Secure Random Generation**: Uses cryptographically secure random number generation

### 🔒 Best Practices for Users

#### Password Security
- Use passwords of at least 12 characters (recommended)
- Include a mix of uppercase, lowercase, numbers, and symbols
- Never reuse passwords across different projects
- Use a password manager to generate and store strong passwords
- Rotate passwords regularly, especially after potential compromise

#### File Handling
- Store encrypted `.env.encrypted` files securely
- Never commit encrypted files to version control
- Use secure file permissions (readable only by owner)
- Backup encrypted files in secure locations
- Delete unencrypted `.env` files after encryption

#### Key Management
- Distribute decryption passwords securely (not via email/chat)
- Use different passwords for different environments (dev/staging/prod)
- Implement password rotation policies
- Store passwords in secure vaults or password managers

#### Operational Security
- Run encryption/decryption operations on trusted systems only
- Verify file integrity before and after operations
- Monitor for unauthorized access attempts
- Log encryption/decryption operations for audit purposes

### ⚠️ Security Limitations

- Password-based encryption (not key-based)
- No built-in key rotation mechanism
- Files are encrypted individually (not envelope encryption)
- No integration with external key management systems

For high-security environments, consider additional measures like:
- Using hardware security modules (HSM)
- Implementing envelope encryption
- Integrating with enterprise key management systems

## Security Updates

Security updates will be released as patch versions (e.g., 1.1.1). We will announce critical security updates through:

- GitHub Releases
- Changelog.md
- Relevant community channels

### How to Stay Secure

- Subscribe to our GitHub Releases
- Regularly update to the latest version
- Follow security best practices mentioned in our README.md

## Contact

If you have questions about this Security Policy or concerns about security, please contact us via GitHub issues or email the maintainers.
