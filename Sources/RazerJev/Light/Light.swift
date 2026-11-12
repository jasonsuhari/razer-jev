struct RGB: Equatable {
    let red: UInt8, green: UInt8, blue: UInt8

    static let red = RGB(red: 255, green: 0, blue: 0)
    static let green = RGB(red: 0, green: 255, blue: 0)
    static let off = RGB(red: 0, green: 0, blue: 0)

    static let named: [(name: String, color: RGB)] = [("Red", .red), ("Green", .green), ("Off", .off)]
}

protocol Light {
    func show(_ color: RGB) throws
}
