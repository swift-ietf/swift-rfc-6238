import Dependency

extension RFC_6238 {

    public struct TOTP: Codable, Hashable, Sendable {

        public let secret: [UInt8]

        public let timeStep: Double

        public let digits: Int

        public let algorithm: Algorithm

        public let t0: Double

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

extension RFC_6238.TOTP {

    public func counter(at unixTime: Double) -> UInt64 {
        UInt64((unixTime - t0) / timeStep)
    }

    public func generate<HMACProvider: RFC_6238.HMACProvider>(
        at unixTime: Double,
        using hmacProvider: HMACProvider
    ) -> Swift.String {
        let counter = self.counter(at: unixTime)
        let hotp = RFC_6238.HOTP(validatedSecret: secret, digits: digits, algorithm: algorithm)
        return hotp.generate(counter: counter, using: hmacProvider)
    }

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

    public func timeRemaining(at unixTime: Double) -> Double {
        let elapsedInStep = (unixTime - t0).truncatingRemainder(dividingBy: timeStep)
        return timeStep - elapsedInStep
    }

    public func provisioningURI(
        label: Swift.String,
        issuer: Swift.String? = nil
    ) -> Swift.String {
        let encodedLabel = percentEncode(label)
        var uri = "otpauth://totp/\(encodedLabel)"
        uri += "?secret=\(RFC_6238.Base32.encode(secret))"

        uri += "&algorithm=\(algorithm.rawValue.uppercased())"
        uri += "&digits=\(digits)"
        uri += "&period=\(Int(timeStep))"
        if let issuer {
            uri += "&issuer=\(percentEncode(issuer))"
        }
        return uri
    }
}

extension RFC_6238.TOTP {

    public func generate(at unixTime: Double) -> Swift.String {
        generate(at: unixTime, using: Dependency.Scope.current[RFC_6238.HMAC.self])
    }

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
