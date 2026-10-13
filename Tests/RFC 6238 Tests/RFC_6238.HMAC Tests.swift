import Testing

@testable import RFC_6238

extension `RFC 6238 Tests` {

    @Suite
    struct `RFC 6238 Appendix B through the live HMAC` {

        static let vectors: [(RFC_6238.Algorithm, Swift::String, [(Double, Swift::String)])] = [
            (
                .sha1, "12345678901234567890",
                [
                    (59, "94287082"),
                    (1_111_111_109, "07081804"),
                    (1_111_111_111, "14050471"),
                    (1_234_567_890, "89005924"),
                    (2_000_000_000, "69279037"),
                    (20_000_000_000, "65353130"),
                ]
            ),
            (
                .sha256, "12345678901234567890123456789012",
                [
                    (59, "46119246"),
                    (1_111_111_109, "68084774"),
                    (1_111_111_111, "67062674"),
                    (1_234_567_890, "91819424"),
                    (2_000_000_000, "90698825"),
                    (20_000_000_000, "77737706"),
                ]
            ),
            (
                .sha512, "1234567890123456789012345678901234567890123456789012345678901234",
                [
                    (59, "90693936"),
                    (1_111_111_109, "25091201"),
                    (1_111_111_111, "99943326"),
                    (1_234_567_890, "93441116"),
                    (2_000_000_000, "38618901"),
                    (20_000_000_000, "47863826"),
                ]
            ),
        ]

        @Test(arguments: [RFC_6238.Algorithm.sha1, .sha256, .sha512])
        func `RFC 6238 Appendix B vectors match the live HMAC`(algorithm: RFC_6238.Algorithm) throws {
            let (_, seed, cases) = Self.vectors.first { $0.0 == algorithm }!
            let totp = try RFC_6238.TOTP(
                secret: Array(seed.utf8),
                timeStep: 30,
                digits: 8,
                algorithm: algorithm,
                t0: 0
            )
            for (unixTime, expected) in cases {
                #expect(try totp.generate(at: unixTime, using: RFC_6238.HMAC.liveValue) == expected)
            }
        }

        @Test
        func `RFC 4226 Appendix D HOTP vectors match the live HMAC`() throws {
            let hotp = try RFC_6238.HOTP(secret: Array("12345678901234567890".utf8))
            let expected = [
                "755224", "287082", "359152", "969429", "338314",
                "254676", "287922", "162583", "399871", "520489",
            ]
            for (counter, code) in expected.enumerated() {
                #expect(try hotp.generate(counter: UInt64(counter), using: RFC_6238.HMAC.liveValue) == code)
            }
        }

        @Test
        func `RFC 2104 hashes keys longer than the block size first`() {
            let live = RFC_6238.HMAC.liveValue
            let data = Array("Test Using Larger Than Block-Size Key - Hash Key First".utf8)
            #expect(
                hexString(live.hmac(algorithm: .sha1, key: [UInt8](repeating: 0xaa, count: 80), data: data))
                    == "aa4ae5e15272d00e95705637ce8a3b55ed402112"
            )
            #expect(
                hexString(live.hmac(algorithm: .sha256, key: [UInt8](repeating: 0xaa, count: 131), data: data))
                    == "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54"
            )
            #expect(
                hexString(live.hmac(algorithm: .sha512, key: [UInt8](repeating: 0xaa, count: 131), data: data))
                    == "80b24263c7c1a3ebb71493c1dd7be8b49b46d1f41b4aeec1121b013783f8f3526b56d037e05f2598bd0fd2215d6a1e5295e64f73f63f0aec8b915a985d786598"
            )
        }
    }
}

extension `RFC 6238 Tests` {

    @Suite
    struct `RFC 4226 §5.3 dynamic truncation` {

        struct ShortHMACProvider: RFC_6238.HMACProvider {
            func hmac(algorithm: RFC_6238.Algorithm, key: [UInt8], data: [UInt8]) -> [UInt8] {
                [UInt8](repeating: 0x0f, count: 10)
            }
        }

        @Test
        func `RFC 4226 §5.3 rejects an HMAC shorter than 20 bytes with a typed error`() throws {
            let hotp = try RFC_6238.HOTP(secret: Array("12345678901234567890".utf8))
            #expect(throws: RFC_6238.Error.hmacTooShort(10)) {
                try hotp.generate(counter: 0, using: ShortHMACProvider())
            }
        }
    }
}
