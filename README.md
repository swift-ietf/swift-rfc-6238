# swift-rfc-6238

Use this package for time-based one-time passwords (TOTP), the codes of authenticator apps, either to generate them or to check one a person typed. Start from `RFC_6238.TOTP`. It is HOTP from swift-rfc-4226 with the number of time steps as the counter.

## Laws

- Codes and step counts match RFC 6238 Appendix B for HMAC-SHA-1, -256 and -512.
- Times are Unix times in whole seconds. The step count is the number of whole steps since `t0`, so with 30-second steps the times 30 to 59 share step 1. A time before `t0` is refused, never clamped.
- The defaults are those authenticator apps expect: HMAC-SHA-1, 6 digits, 30-second steps from the Unix epoch.
- `validate(_:at:window:)` accepts a code from any step within `window` steps of the current one, one by default, and returns that step. Storing it and refusing any code whose step is not later stops a code being used twice. The window stops at `t0` and at the largest step, and every step in it is compared.
- `secondsRemaining(at:)` is a full step, never zero, at a step boundary.
- Secrets are bytes. Reading a Base32 secret is swift-rfc-4648's job, and the `otpauth` URI that authenticator apps scan is not part of RFC 6238.
