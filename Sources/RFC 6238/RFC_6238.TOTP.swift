import Dependency_Primitives

extension RFC_6238 {
    /// Represents a Time-Based One-Time Password (TOTP) configuration
    public struct TOTP: Codable, Hashable, Sendable {
        /// The shared secret key
        public let secret: [UInt8]

        /// The time step in seconds (default: 30)
        public let timeStep: Double

        /// The number of digits in the generated OTP (default: 6, range: 6-8)
        public let digits: Int

        /// The HMAC algorithm to use
        public let algorithm: Algorithm

        /// The initial counter time (T0) - Unix time to start counting time steps (default: 0)
        public let t0: Double

        /// Creates a TOTP configuration
        /// - Parameters:
        ///   - secret: The shared secret key
        ///   - timeStep: The time step in seconds (default: 30)
        ///   - digits: The number of digits in the OTP (default: 6, must be 6-8)
        ///   - algorithm: The HMAC algorithm (default: SHA1)
        ///   - t0: The initial counter time (default: 0)
        /// - Throws: `Error.invalidDigits` if digits is not between 6-8, `Error.invalidTimeStep` if timeStep is not positive, `Error.emptySecret` if secret is empty
        public init(
            secret: [UInt8],
            timeStep: Double = 30,
            digits: Int = 6,
            algorithm: Algorithm = .sha1,
            t0: Double = 0
        ) throws(Error) {
            guard !secret.isEmpty else {
                throw Error.emptySecret
            }
            guard (6...8).contains(digits) else {
                throw Error.invalidDigits("Digits must be between 6 and 8, got \(digits)")
            }
            guard timeStep > 0 else {
                throw Error.invalidTimeStep("Time step must be positive, got \(timeStep)")
            }

            self.secret = secret
            self.timeStep = timeStep
            self.digits = digits
            self.algorithm = algorithm
            self.t0 = t0
        }

        /// Creates a TOTP configuration from a base32 encoded secret
        /// - Parameters:
        ///   - base32Secret: The base32 encoded secret
        ///   - timeStep: The time step in seconds (default: 30)
        ///   - digits: The number of digits in the OTP (default: 6)
        ///   - algorithm: The HMAC algorithm (default: SHA1)
        ///   - t0: The initial counter time (default: 0)
        /// - Throws: `Error.invalidBase32String` if base32 decoding fails, or other validation errors
        public init(
            base32Secret: Swift.String,
            timeStep: Double = 30,
            digits: Int = 6,
            algorithm: Algorithm = .sha1,
            t0: Double = 0
        ) throws(Error) {
            guard let secret = Base32.decode(base32Secret) else {
                throw Error.invalidBase32String
            }

            try self.init(
                secret: secret,
                timeStep: timeStep,
                digits: digits,
                algorithm: algorithm,
                t0: t0
            )
        }
    }
}

// MARK: - TOTP Methods

extension RFC_6238.TOTP {
    /// Calculates the time-based counter value T
    /// - Parameter unixTime: Unix timestamp in seconds since epoch
    /// - Returns: The counter value T
    public func counter(at unixTime: Double) -> UInt64 {
        UInt64((unixTime - t0) / timeStep)
    }

    /// Generates an OTP for a given time using the provided HMAC implementation
    /// - Parameters:
    ///   - unixTime: Unix timestamp in seconds since epoch
    ///   - hmacProvider: The HMAC provider implementation
    /// - Returns: The generated OTP as a string with leading zeros if necessary
    public func generate<HMACProvider: RFC_6238.HMACProvider>(
        at unixTime: Double,
        using hmacProvider: HMACProvider
    ) -> Swift.String {
        let counter = self.counter(at: unixTime)
        let hotp = RFC_6238.HOTP(validatedSecret: secret, digits: digits, algorithm: algorithm)
        return hotp.generate(counter: counter, using: hmacProvider)
    }

    /// Validates an OTP within a time window
    /// - Parameters:
    ///   - otp: The OTP to validate
    ///   - unixTime: Unix timestamp in seconds since epoch
    ///   - window: The number of time steps to check before and after current time (default: 1)
    ///   - hmacProvider: The HMAC provider implementation
    /// - Returns: True if the OTP is valid within the window
    public func validate<HMACProvider: RFC_6238.HMACProvider>(
        _ otp: Swift.String,
        at unixTime: Double,
        window: Int = 1,
        using hmacProvider: HMACProvider
    ) -> Bool {
        let currentCounter = counter(at: unixTime)

        return (-window...window).contains { offset in
            let testCounter = UInt64(Int64(currentCounter) + Int64(offset))
            let hotp = RFC_6238.HOTP(validatedSecret: secret, digits: digits, algorithm: algorithm)
            let expectedOTP = hotp.generate(counter: testCounter, using: hmacProvider)
            return constantTimeCompare(otp, expectedOTP)
        }
    }

    /// Generates the remaining seconds until the next OTP
    /// - Parameter unixTime: Unix timestamp in seconds since epoch
    /// - Returns: Seconds remaining until next OTP
    public func timeRemaining(at unixTime: Double) -> Double {
        let elapsedInStep = (unixTime - t0).truncatingRemainder(dividingBy: timeStep)
        return timeStep - elapsedInStep
    }

    /// Generates a URI for provisioning the TOTP in authenticator apps
    /// - Parameters:
    ///   - label: The account label (e.g., "user@example.com")
    ///   - issuer: The service issuer (e.g., "Example Corp")
    /// - Returns: The otpauth URI string
    public func provisioningURI(
        label: Swift.String,
        issuer: Swift.String? = nil
    ) -> Swift.String {
        let encodedLabel = percentEncode(label)
        var uri = "otpauth://totp/\(encodedLabel)"
        uri += "?secret=\(RFC_6238.Base32.encode(secret))"
        // swift-linter:disable:next raw value access
        // REASON: same-package implementation — `Algorithm` and `TOTP` are both nested members of `RFC_6238`.
        // swift-linter:disable:next chained rawvalue access
        // REASON: same-package implementation — `.rawValue.uppercased()` projects `Algorithm`'s own wire text.
        uri += "&algorithm=\(algorithm.rawValue.uppercased())"
        uri += "&digits=\(digits)"
        uri += "&period=\(Int(timeStep))"
        if let issuer {
            uri += "&issuer=\(percentEncode(issuer))"
        }
        return uri
    }
}

// MARK: - Convenience (Dependency-resolved)

extension RFC_6238.TOTP {
    /// Generates an OTP using the HMAC provider from dependency scope.
    ///
    /// - Parameter unixTime: Unix timestamp in seconds since epoch
    /// - Returns: The generated OTP string
    public func generate(at unixTime: Double) -> Swift.String {
        generate(at: unixTime, using: Dependency.Scope.current[RFC_6238.HMAC.self])
    }

    /// Validates an OTP using the HMAC provider from dependency scope.
    ///
    /// - Parameters:
    ///   - otp: The OTP to validate
    ///   - unixTime: Unix timestamp in seconds since epoch
    ///   - window: The number of time steps to check (default: 1)
    /// - Returns: True if the OTP is valid within the window
    public func validate(
        _ otp: Swift.String,
        at unixTime: Double,
        window: Int = 1
    ) -> Bool {
        validate(
            otp,
            at: unixTime,
            window: window,
            using: Dependency.Scope.current[RFC_6238.HMAC.self]
        )
    }
}
