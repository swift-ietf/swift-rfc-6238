extension RFC_6238 {

    public protocol HMACProvider: Sendable {

        func hmac(algorithm: Algorithm, key: [UInt8], data: [UInt8]) -> [UInt8]
    }
}
