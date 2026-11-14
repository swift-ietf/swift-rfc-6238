extension RFC_6238 {

    /// The HMAC hash a TOTP generator uses (section 1.2): SHA-1, as RFC 4226 defines, or SHA-256 or SHA-512.
    public enum Algorithm: String, Sendable, Hashable, CaseIterable {
        case sha1 = "SHA1"
        case sha256 = "SHA256"
        case sha512 = "SHA512"
    }
}

extension RFC_6238.Algorithm {

    /// The hash function itself.
    public var hash: RFC_2104.Hash {
        switch self {
        case .sha1: .sha1
        case .sha256: .sha256
        case .sha512: .sha512
        }
    }
}
