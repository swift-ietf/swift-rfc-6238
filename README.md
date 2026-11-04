# swift-rfc-6238

Use this package when you need time-based or counter-based one-time passwords, the six-to-eight digit codes of authenticator apps, either to generate them or to check a code a user typed. Start from `RFC_6238.TOTP` for time-based codes and `RFC_6238.HOTP` for counter-based ones.

## Laws

- Codes match the test vectors of RFC 6238 Appendix B and RFC 4226 Appendix D with the built-in HMAC. It is HMAC as in RFC 2104, over SHA-1, SHA-256 or SHA-512, and hashes a key longer than the block size first.
- A code is always exactly `digits` characters long, with leading zeros kept.
- The time step counter is the whole number of steps since `t0`, so with 30-second steps the times 30 to 59 share counter 1. `RFC_6238.TOTP.timeRemaining(at:)` gives a full step, not zero, at a step boundary.
- `RFC_6238.TOTP.validate(_:at:window:)` accepts a code from any step within `window` steps before or after the current one, one step by default. It compares in constant time and checks every step in the window, even after a match.
- A Base32 secret is read case-insensitively, and spaces, hyphens and padding are ignored.
- A custom `RFC_6238.HMACProvider` must return at least 20 bytes. A shorter result fails code generation.
- `RFC_6238.TOTP.provisioningURI(label:issuer:)` writes an otpauth URI with the secret in Base32 and the algorithm, digits and period. Label and issuer are percent-encoded except for unreserved characters and the at sign, so a space becomes `%20`. The period is written in whole seconds.
