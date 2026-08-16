# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-08-20

### Added
- Initial release of swift-rfc-6238
- Complete implementation of RFC 6238 (TOTP: Time-Based One-Time Password Algorithm)
- Complete implementation of RFC 4226 (HOTP: HMAC-Based One-Time Password Algorithm)
- Protocol-based HMAC provider design for crypto library independence
- Throwing initializers for safe error handling
- Base32 encoding/decoding support (RFC 4648 Section 5)
- Time window validation for TOTP
- Provisioning URI generation for authenticator apps
- Constant-time comparison to prevent timing attacks
- Comprehensive test suite using Swift Testing framework
- Support for SHA1, SHA256, and SHA512 hash algorithms
- Configurable time step and digit length (6-8 digits)
- Time remaining calculation for TOTP codes
- Zero dependencies - pure Swift implementation

### Security
- Replaced precondition checks with throwing initializers for better error handling
- Implemented constant-time string comparison to prevent timing attacks
- No hardcoded secrets or keys in the implementation

### Testing
- Full test coverage using Swift Testing framework
- Mock HMAC provider support for easy testing
- Test vectors from RFC specifications
