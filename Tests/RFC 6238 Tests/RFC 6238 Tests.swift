import Testing

import RFC_6238

@Suite
struct `RFC 6238 Tests` {

    static let times: [Int64] = [59, 1_111_111_109, 1_111_111_111, 1_234_567_890, 2_000_000_000, 20_000_000_000]

    @Test
    func `Appendix B test vectors for SHA-1`() throws {
        let totp = try RFC_6238.TOTP(secret: Array("12345678901234567890".utf8), digits: 8, algorithm: .sha1)
        let codes = ["94287082", "07081804", "14050471", "89005924", "69279037", "65353130"]
        for (time, code) in zip(Self.times, codes) {
            #expect(try totp.code(at: time) == code)
        }
    }

    @Test
    func `Appendix B test vectors for SHA-256`() throws {
        let totp = try RFC_6238.TOTP(
            secret: Array("12345678901234567890123456789012".utf8),
            digits: 8,
            algorithm: .sha256
        )
        let codes = ["46119246", "68084774", "67062674", "91819424", "90698825", "77737706"]
        for (time, code) in zip(Self.times, codes) {
            #expect(try totp.code(at: time) == code)
        }
    }

    @Test
    func `Appendix B test vectors for SHA-512`() throws {
        let totp = try RFC_6238.TOTP(
            secret: Array("1234567890123456789012345678901234567890123456789012345678901234".utf8),
            digits: 8,
            algorithm: .sha512
        )
        let codes = ["90693936", "25091201", "99943326", "93441116", "38618901", "47863826"]
        for (time, code) in zip(Self.times, codes) {
            #expect(try totp.code(at: time) == code)
        }
    }

    @Test
    func `Appendix B step counts`() throws {
        let totp = try RFC_6238.TOTP(secret: Array("12345678901234567890".utf8))
        let counters: [UInt64] = [0x1, 0x23523EC, 0x23523ED, 0x273EF07, 0x3F940AA, 0x27BC86AA]
        for (time, counter) in zip(Self.times, counters) {
            #expect(try totp.counter(at: time) == counter)
        }
    }

    @Test
    func `validate accepts one step either side by default and returns the step`() throws {
        let totp = try RFC_6238.TOTP(secret: Array("12345678901234567890".utf8))
        let now: Int64 = 1_111_111_111
        let step = try totp.counter(at: now)
        #expect(try totp.validate(try totp.code(at: now), at: now) == step)
        #expect(try totp.validate(try totp.code(at: now - 30), at: now) == step - 1)
        #expect(try totp.validate(try totp.code(at: now + 30), at: now) == step + 1)
        #expect(try totp.validate(try totp.code(at: now - 60), at: now) == nil)
        #expect(try totp.validate(try totp.code(at: now - 60), at: now, window: 0) == nil)
        #expect(try totp.validate(try totp.code(at: now), at: now, window: 0) == step)
    }

    @Test
    func `the window does not reach before T0`() throws {
        let totp = try RFC_6238.TOTP(secret: Array("12345678901234567890".utf8), t0: 1000)
        #expect(try totp.validate(try totp.code(at: 1000), at: 1010, window: 5) == 0)
        #expect(throws: RFC_6238.Error.beforeT0(999)) { try totp.code(at: 999) }
    }

    @Test
    func `seconds remaining is a full step at a step boundary`() throws {
        let totp = try RFC_6238.TOTP(secret: Array("12345678901234567890".utf8))
        #expect(try totp.secondsRemaining(at: 60) == 30)
        #expect(try totp.secondsRemaining(at: 59) == 1)
        #expect(try totp.secondsRemaining(at: 75) == 15)
    }

    @Test
    func `a generator refuses a zero time step and what HOTP refuses`() {
        let secret = Array("12345678901234567890".utf8)
        #expect(throws: RFC_6238.Error.timeStep) { try RFC_6238.TOTP(secret: secret, timeStep: 0) }
        #expect(throws: RFC_6238.Error.hotp(.emptySecret)) { try RFC_6238.TOTP(secret: []) }
        #expect(throws: RFC_6238.Error.hotp(.digits(5))) { try RFC_6238.TOTP(secret: secret, digits: 5) }
    }
}
