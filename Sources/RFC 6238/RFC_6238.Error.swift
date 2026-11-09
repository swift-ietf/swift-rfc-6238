extension RFC_6238 {

    public enum Error: Swift::Error, Sendable, Equatable {
        case invalidBase32String
        case invalidDigits(Swift::String)
        case invalidTimeStep(Swift::String)
        case invalidTime(Swift::String)
        case emptySecret
        case hmacTooShort(Int)
    }
}

extension RFC_6238.Error: CustomStringConvertible {
    public var description: Swift::String {
        switch self {
        case .invalidBase32String:
            "Invalid base32 encoded string"

        case .invalidDigits(let message):
            "Invalid digits: \(message)"

        case .invalidTimeStep(let message):
            "Invalid time step: \(message)"

        case .invalidTime(let message):
            "Invalid time: \(message)"

        case .emptySecret:
            "Secret key cannot be empty"

        case .hmacTooShort(let count):
            "HMAC too short: \(count) bytes"
        }
    }
}
