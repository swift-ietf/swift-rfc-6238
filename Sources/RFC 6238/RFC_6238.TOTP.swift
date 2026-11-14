extension RFC_6238 {

    /// A TOTP generator (section 4): HOTP whose counter is the number of whole time steps since `T0`.
    ///
    /// Times are Unix times in whole seconds.
    public struct TOTP: Sendable {

        /// The HOTP generator the codes come from.
        public let hotp: RFC_4226.HOTP

        /// The hash of HMAC.
        public let algorithm: Algorithm

        /// `X`: the length of one time step, in seconds.
        public let timeStep: UInt64

        /// `T0`: the Unix time at which counting starts.
        public let t0: Int64

        /// A generator; the defaults are those of section 4.1 and of authenticator apps: 30-second steps from the Unix
        /// epoch, 6 digits, HMAC-SHA-1.
        public init(
            secret: [UInt8],
            timeStep: UInt64 = 30,
            digits: Int = 6,
            algorithm: Algorithm = .sha1,
            t0: Int64 = 0
        ) throws(RFC_6238.Error) {
            guard timeStep > 0 else { throw .timeStep }
            do {
                self.hotp = try RFC_4226.HOTP(secret: secret, digits: digits, hash: algorithm.hash)
            } catch {
                throw .hotp(error)
            }
            self.algorithm = algorithm
            self.timeStep = timeStep
            self.t0 = t0
        }
    }
}

extension RFC_6238.TOTP {

    /// `T`: the number of whole time steps between `T0` and `time` (section 4.2).
    public func counter(at time: Int64) throws(RFC_6238.Error) -> UInt64 {
        guard time >= t0 else { throw .beforeT0(time) }
        let elapsed = UInt64(bitPattern: time &- t0)
        return elapsed / timeStep
    }

    /// The code at `time`.
    public func code(at time: Int64) throws(RFC_6238.Error) -> String {
        hotp.code(counter: try counter(at: time))
    }

    /// The step whose code is `code`, among the current step and `window` steps before and after it, or `nil` when
    /// none matches (section 5.2).
    ///
    /// The window never reaches before `T0`. Every step in it is compared, whether or not one matched. A server
    /// stores the returned step and refuses any code whose step is not later, so that no code is accepted twice.
    public func validate(_ code: String, at time: Int64, window: UInt64 = 1) throws(RFC_6238.Error) -> UInt64? {
        let current = try counter(at: time)
        let first = current >= window ? current - window : 0
        let span = current - first + (UInt64.max - current >= window ? window : UInt64.max - current)
        return hotp.validate(code, counter: first, lookAhead: span)
    }

    /// The seconds from `time` until the next step begins: `timeStep` at the very start of a step.
    public func secondsRemaining(at time: Int64) throws(RFC_6238.Error) -> UInt64 {
        guard time >= t0 else { throw .beforeT0(time) }
        let elapsed = UInt64(bitPattern: time &- t0)
        return timeStep - elapsed % timeStep
    }
}
