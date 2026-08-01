// RFC 6238.swift
// swift-rfc-6238
//
// Implementation of RFC 6238: TOTP: Time-Based One-Time Password Algorithm
// Pure Swift implementation with no Foundation dependencies.

import ASCII_Primitives

/// Implementation of RFC 6238: TOTP: Time-Based One-Time Password Algorithm
///
/// See: https://www.rfc-editor.org/rfc/rfc6238.html
public enum RFC_6238 {}

// MARK: - Helper Functions

/// Performs constant-time string comparison to prevent timing attacks
func constantTimeCompare(_ a: Swift.String, _ b: Swift.String) -> Bool {
    guard a.count == b.count else { return false }

    var result = 0
    for (charA, charB) in zip(a, b) {
        result |= Int(charA.asciiValue ?? 0) ^ Int(charB.asciiValue ?? 0)
    }

    return result == 0
}

/// Formats an integer with leading zeros to the specified width.
func zeroPadded(_ value: UInt32, width: Int) -> Swift.String {
    var s = Swift.String(value)
    while s.count < width { s = "0" + s }
    return s
}

/// Percent-encodes a string for use in URIs (RFC 3986 unreserved characters).
///
/// Scans the UTF-8 byte view directly ([IMPL-089]): ASCII-safe bytes append as-is;
/// every other byte — including each byte of a multi-byte UTF-8 sequence — is
/// percent-encoded individually, byte-for-byte identical to scanning `.unicodeScalars`
/// and then re-encoding each non-ASCII scalar's UTF-8 bytes.
func percentEncode(_ string: Swift.String) -> Swift.String {
    var result = ""
    for byte in string.utf8 {
        if (byte >= 0x41 && byte <= 0x5A)  // A-Z
            || (byte >= 0x61 && byte <= 0x7A)  // a-z
            || (byte >= 0x30 && byte <= 0x39)  // 0-9
            || byte == 0x2D || byte == 0x5F || byte == 0x2E || byte == 0x7E  // - _ . ~
            || byte == 0x40  // @ (safe in otpauth label)
        {
            result.append(Character(UnicodeScalar(byte)))
        } else {
            result += "%"
            result.append(hexChar(byte >> 4))
            result.append(hexChar(byte & 0x0F))
        }
    }
    return result
}

private func hexChar(_ nibble: UInt8) -> Character {
    // Delegates the uppercase hex nibble->digit mapping to the L1 single-byte
    // ASCII primitive. `nibble` is always masked to 0-15 at the call sites
    // (`byte >> 4`, `byte & 0x0F`), so the result is non-nil; the force-unwrap
    // preserves the original table's trap-on-out-of-domain behavior exactly.
    Character(UnicodeScalar(ASCII.Hexadecimal.code(nibble, case: .upper)!))
}
