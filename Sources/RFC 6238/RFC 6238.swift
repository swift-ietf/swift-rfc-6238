import ASCII

public enum RFC_6238 {}

func constantTimeCompare(_ a: Swift.String, _ b: Swift.String) -> Bool {
    guard a.count == b.count else { return false }

    var result = 0
    for (charA, charB) in zip(a, b) {
        result |= Int(charA.asciiValue ?? 0) ^ Int(charB.asciiValue ?? 0)
    }

    return result == 0
}

func zeroPadded(_ value: UInt32, width: Int) -> Swift.String {
    var s = Swift.String(value)
    while s.count < width { s = "0" + s }
    return s
}

func percentEncode(_ string: Swift.String) -> Swift.String {
    var result = ""
    for byte in string.utf8 {
        if (byte >= 0x41 && byte <= 0x5A)
            || (byte >= 0x61 && byte <= 0x7A)
            || (byte >= 0x30 && byte <= 0x39)
            || byte == 0x2D || byte == 0x5F || byte == 0x2E || byte == 0x7E
            || byte == 0x40
        {
            result.append(Character(UnicodeScalar(byte)))
        } else {
            result += "%"
            result.append(hexChar(byte >> 4))
            result.append(hexChar(byte & 0x0F))
        }
    }
    return result
}

private func hexChar(_ nibble: UInt8) -> Character {

    Character(UnicodeScalar(ASCII.Hexadecimal.code(nibble, case: .upper)!))
}
