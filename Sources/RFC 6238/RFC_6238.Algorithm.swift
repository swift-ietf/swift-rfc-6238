extension RFC_6238 {

    public enum Algorithm: Swift.String, Codable, Hashable, CaseIterable, Sendable {
        case sha1 = "SHA1"
        case sha256 = "SHA256"
        case sha512 = "SHA512"
    }
}

extension RFC_6238.Algorithm {

    public var hashLength: Int {
        switch self {
        case .sha1: 20
        case .sha256: 32
        case .sha512: 64
        }
    }
}
