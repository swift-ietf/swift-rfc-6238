public import Dependency

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

    #if canImport(CryptoKit)
        public static var liveValue: RFC_6238.HMAC {
            RFC_6238.HMAC { _, _, _ in

                fatalError(
                    "RFC_6238.HMAC.liveValue: CryptoKit HMAC integration required. "
                        + "Inject a provider via Dependency.Scope.with { $0[RFC_6238.HMAC.self] = ... }"
                )
            }
        }
    #else
        public static var liveValue: RFC_6238.HMAC {
            RFC_6238.HMAC { _, _, _ in
                fatalError(
                    "RFC_6238.HMAC.liveValue unavailable on this platform. "
                        + "Inject a provider via Dependency.Scope.with { $0[RFC_6238.HMAC.self] = ... }"
                )
            }
        }
    #endif

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
