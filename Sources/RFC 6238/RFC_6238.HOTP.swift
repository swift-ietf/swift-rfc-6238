import Dependency

extension RFC_6238 {

    public struct HOTP: Codable, Hashable, Sendable {

        public let secret: [UInt8]

        public let digits: Int

        public let algorithm: Algorithm

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

extension RFC_6238.HOTP {

    public func generate<HMACProvider: RFC_6238.HMACProvider>(
        counter: UInt64,
        using hmacProvider: HMACProvider
    ) throws(RFC_6238.Error) -> Swift.String {

        let counterBytes: [UInt8] = withUnsafeBytes(of: counter.bigEndian) { unsafe Array($0) }

        let hmac = hmacProvider.hmac(algorithm: algorithm, key: secret, data: counterBytes)

        let truncated = try dynamicTruncate(hmac)

        var divisor: UInt32 = 1
        for _ in 0..<digits { divisor *= 10 }
        let otp = truncated % divisor

        return zeroPadded(otp, width: digits)
    }

    private func dynamicTruncate(_ hmac: [UInt8]) throws(RFC_6238.Error) -> UInt32 {
        guard let last = hmac.last, hmac.count >= 20 else {
            throw .hmacTooShort(hmac.count)
        }

        let offset = Int(last & 0x0f)

        var value: UInt32 = 0
        (offset..<(offset + 4)).forEach { i in
            value = (value << 8) | UInt32(hmac[i])
        }

        return value & 0x7fff_ffff
    }
}

extension RFC_6238.HOTP {

    public func generate(counter: UInt64) throws(RFC_6238.Error) -> Swift.String {
        try generate(counter: counter, using: Dependency.Scope.current[RFC_6238.HMAC.self])
    }
}
