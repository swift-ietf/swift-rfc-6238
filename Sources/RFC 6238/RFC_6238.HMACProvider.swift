extension RFC_6238 {
    /// Protocol for providing HMAC implementations
    /// This allows the RFC implementation to remain crypto-library agnostic
    public protocol HMACProvider: Sendable {
        /// Computes HMAC for the given algorithm, key, and data
        /// - Parameters:
        ///   - algorithm: The HMAC algorithm to use
        ///   - key: The secret key
        ///   - data: The data to authenticate
        /// - Returns: The HMAC value
        func hmac(algorithm: Algorithm, key: [UInt8], data: [UInt8]) -> [UInt8]
    }
}
