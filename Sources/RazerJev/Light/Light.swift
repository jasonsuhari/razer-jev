struct RGB: Equatable {
    let red: UInt8, green: UInt8, blue: UInt8

    static let red = RGB(red: 255, green: 0, blue: 0)
    static let green = RGB(red: 0, green: 255, blue: 0)
    static let off = RGB(red: 0, green: 0, blue: 0)

    static let named: [(name: String, color: RGB)] = [("Red", .red), ("Green", .green), ("Off", .off)]

    static let palette: [String: RGB] = [
        "red": .red, "green": .green, "off": .off,
        "blue": RGB(red: 0, green: 0, blue: 255),
        "yellow": RGB(red: 255, green: 200, blue: 0),
        "orange": RGB(red: 255, green: 80, blue: 0),
        "purple": RGB(red: 150, green: 0, blue: 255),
        "pink": RGB(red: 255, green: 0, blue: 120),
        "cyan": RGB(red: 0, green: 255, blue: 255),
        "white": RGB(red: 255, green: 255, blue: 255),
    ]

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init?(_ text: String) {
        let text = text.lowercased()
        if let known = Self.palette[text] { self = known; return }
        guard text.hasPrefix("#"), text.count == 7, let value = UInt32(text.dropFirst(), radix: 16) else { return nil }
        self.init(red: UInt8(value >> 16 & 0xFF), green: UInt8(value >> 8 & 0xFF), blue: UInt8(value & 0xFF))
    }
}

protocol Light {
    func show(_ color: RGB) throws
}
