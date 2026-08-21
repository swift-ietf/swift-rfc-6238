extension RFC_6238 {

    public enum Base32 {}
}

extension RFC_6238.Base32 {
    private static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    public static func decode(_ base32: Swift.String) -> [UInt8]? {
        let cleaned = base32.uppercased().filter { char in
            char != " " && char != "-" && char != "="
        }

        var bits = 0
        var value = 0
        var output = [UInt8]()

        for char in cleaned {
            guard let idx = alphabet.firstIndex(of: char) else {
                return nil
            }
            value = (value << 5) | alphabet.distance(from: alphabet.startIndex, to: idx)
            bits += 5

            if bits >= 8 {
                output.append(UInt8((value >> (bits - 8)) & 0xFF))
                bits -= 8
            }
        }

        return output
    }

    public static func encode(_ bytes: [UInt8]) -> Swift.String {
        var result = ""
        var bits = 0
        var value = 0

        for byte in bytes {
            value = (value << 8) | Int(byte)
            bits += 8

            while bits >= 5 {
                let index = (value >> (bits - 5)) & 0x1F
                result.append(alphabet[index])
                bits -= 5
            }
        }

        if bits > 0 {
            let index = (value << (5 - bits)) & 0x1F
            result.append(alphabet[index])
        }

        while result.count % 8 != 0 {
            result.append("=")
        }

        return result
    }
}
