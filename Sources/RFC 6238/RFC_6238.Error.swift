extension RFC_6238 {

    /// Why a TOTP generator cannot be made, or cannot give a code at a time.
    public enum Error: Swift.Error, Sendable, Equatable {

        /// The secret or the number of digits is refused by HOTP.
        case hotp(RFC_4226.Error)

        /// The time step `X` is zero.
        case timeStep

        /// The time lies before `T0`, where the step count `T` is not defined.
        case beforeT0(Int64)
    }
}
