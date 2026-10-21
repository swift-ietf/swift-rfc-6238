internal import Byte
public import Dependency
internal import FIPS_180_4

extension RFC_6238 {

    public struct HMAC: Sendable {
        @usableFromInline
        let _hmac: @Sendable (Algorithm, [UInt8], [UInt8]) -> [UInt8]

        @inlinable
        public init(
            hmac: @escaping @Sendable (Algorithm, [UInt8], [UInt8]) -> [UInt8]
        ) {
            self._hmac = hmac
        }
    }
}

extension RFC_6238.HMAC: RFC_6238.HMACProvider {
    @inlinable
    public func hmac(
        algorithm: RFC_6238.Algorithm,
        key: [UInt8],
        data: [UInt8]
    ) -> [UInt8] {
        _hmac(algorithm, key, data)
    }
}

extension RFC_6238.HMAC: Dependency.Key {
    public typealias Value = RFC_6238.HMAC

    public static var liveValue: RFC_6238.HMAC {
        RFC_6238.HMAC { algorithm, key, data in
            algorithm.authenticationCode(key: key, data: data)
        }
    }

    public static var testValue: RFC_6238.HMAC {
        RFC_6238.HMAC { algorithm, key, data in

            let combined = key + data
            var result = [UInt8](repeating: 0, count: algorithm.hashLength)
            (0..<min(combined.count, result.count)).forEach { i in
                result[i] = combined[i]
            }
            return result
        }
    }
}

extension RFC_6238.Algorithm {

    var blockLength: Int {
        switch self {
        case .sha1, .sha256: 64
        case .sha512: 128
        }
    }

    func digest(_ bytes: [UInt8]) -> [UInt8] {
        let input = bytes.map(Byte.init(_:))
        let digest: FIPS_180_4.Digest =
            switch self {
            case .sha1: FIPS_180_4.SHA1.digest(input)
            case .sha256: FIPS_180_4.SHA256.digest(input)
            case .sha512: FIPS_180_4.SHA512.digest(input)
            }
        return digest.bytes.map(\.underlying)
    }

    func authenticationCode(key: [UInt8], data: [UInt8]) -> [UInt8] {
        let shortKey = key.count > blockLength ? digest(key) : key
        let paddedKey = shortKey + [UInt8](repeating: 0, count: blockLength - shortKey.count)
        let inner = digest(paddedKey.map { $0 ^ 0x36 } + data)
        return digest(paddedKey.map { $0 ^ 0x5c } + inner)
    }
}
