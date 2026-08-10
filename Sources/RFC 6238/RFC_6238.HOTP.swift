import Dependency_Primitives

extension RFC_6238 {
    /// Represents an HMAC-Based One-Time Password (HOTP) configuration
    /// This is the base algorithm used by TOTP (RFC 4226)
    public struct HOTP: Codable, Hashable, Sendable {
        /// The shared secret key
        public let secret: [UInt8]

        /// The number of digits in the generated OTP
        public let digits: Int

        /// The HMAC algorithm to use
        public let algorithm: Algorithm

        /// Creates an HOTP configuration
        /// - Parameters:
        ///   - secret: The shared secret key
        ///   - digits: The number of digits in the OTP (default: 6)
        ///   - algorithm: The HMAC algorithm (default: SHA1)
        /// - Throws: `Error.invalidDigits` if digits is not between 6-8, `Error.emptySecret` if secret is empty
        public init(
            secret: [UInt8],
            digits: Int = 6,
            algorithm: Algorithm = .sha1
        ) throws(Error) {
            guard !secret.isEmpty else {
                throw Error.emptySecret
            }
            guard (6...8).contains(digits) else {
                throw Error.invalidDigits("Digits must be between 6 and 8, got \(digits)")
            }

            self.secret = secret
            self.digits = digits
            self.algorithm = algorithm
        }

        /// Internal initializer that doesn't throw - used when we know parameters are valid
        /// This is used internally by TOTP where parameters have already been validated
        internal init(
            validatedSecret secret: [UInt8],
            digits: Int,
            algorithm: Algorithm
        ) {
            self.secret = secret
            self.digits = digits
            self.algorithm = algorithm
        }
    }
}

// MARK: - HOTP Methods

extension RFC_6238.HOTP {
    /// Generates an OTP for a given counter value
    /// - Parameters:
    ///   - counter: The counter value
    ///   - hmacProvider: The HMAC provider implementation
    /// - Returns: The generated OTP as a string with leading zeros if necessary
    public func generate<HMACProvider: RFC_6238.HMACProvider>(
        counter: UInt64,
        using hmacProvider: HMACProvider
    ) -> Swift.String {
        // Convert counter to big-endian bytes
        let counterBytes: [UInt8] = unsafe withUnsafeBytes(of: counter.bigEndian) { Array($0) }

        // Calculate HMAC
        let hmac = hmacProvider.hmac(algorithm: algorithm, key: secret, data: counterBytes)

        // Dynamic truncation (RFC 4226 Section 5.3)
        let truncated = dynamicTruncate(hmac)

        // Compute OTP value
        var divisor: UInt32 = 1
        for _ in 0..<digits { divisor *= 10 }
        let otp = truncated % divisor

        // Format with leading zeros
        return zeroPadded(otp, width: digits)
    }

    /// Performs dynamic truncation as specified in RFC 4226
    /// - Parameter hmac: The HMAC value to truncate
    /// - Returns: The truncated 31-bit integer
    private func dynamicTruncate(_ hmac: [UInt8]) -> UInt32 {
        guard hmac.count >= 20 else {
            fatalError("HMAC too short: \(hmac.count) bytes")
        }

        // swift-linter:disable:next count minus one
        // REASON: `hmac.last` is the stdlib named idiom for the last-element concept — `hmac.count >= 20` above guarantees non-empty.
        let offset = Int(hmac.last! & 0x0f)

        guard offset + 4 <= hmac.count else {
            fatalError("Invalid offset \(offset) for HMAC length \(hmac.count)")
        }

        var value: UInt32 = 0
        (offset..<(offset + 4)).forEach { i in
            value = (value << 8) | UInt32(hmac[i])
        }

        return value & 0x7fff_ffff
    }
}

// MARK: - Convenience (Dependency-resolved)

extension RFC_6238.HOTP {
    /// Generates an OTP using the HMAC provider from dependency scope.
    ///
    /// - Parameter counter: The counter value
    /// - Returns: The generated OTP string
    public func generate(counter: UInt64) -> Swift.String {
        generate(counter: counter, using: Dependency.Scope.current[RFC_6238.HMAC.self])
    }
}
