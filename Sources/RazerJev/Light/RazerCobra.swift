import Foundation
import IOKit.hid

struct RazerCobra: Light {
    private static let vendorID = 0x1532
    private static let productID = 0x00A3
    private static let reportLength = 90

    func show(_ color: RGB) throws {
        guard let device = Self.controlInterface() else { throw RazerError.notConnected }
        guard IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
            throw RazerError.needsInputMonitoring
        }
        defer { IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone)) }

        let row: UInt8 = 0, firstColumn: UInt8 = 0, lastColumn: UInt8 = 0
        try Self.send(device, commandClass: 0x0F, commandID: 0x03,
                      args: [0, 0, row, firstColumn, lastColumn, color.red, color.green, color.blue])
        let liveOnly: UInt8 = 0, allLEDs: UInt8 = 0, customFrame: UInt8 = 0x08
        try Self.send(device, commandClass: 0x0F, commandID: 0x02, args: [liveOnly, allLEDs, customFrame, 0, 0, 0])
    }

    private static func controlInterface() -> IOHIDDevice? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, [
            kIOHIDVendorIDKey: vendorID,
            kIOHIDProductIDKey: productID,
            kIOHIDPrimaryUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDPrimaryUsageKey: kHIDUsage_GD_Mouse,
        ] as CFDictionary)
        return (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>)?.first
    }

    private static func send(_ device: IOHIDDevice, commandClass: UInt8, commandID: UInt8, args: [UInt8]) throws {
        var report = [UInt8](repeating: 0, count: reportLength)
        report[1] = 0x1F
        report[5] = UInt8(args.count)
        report[6] = commandClass
        report[7] = commandID
        report.replaceSubrange(8..<(8 + args.count), with: args)
        report[88] = report[2..<88].reduce(0, ^)
        guard IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, 0, &report, report.count) == kIOReturnSuccess else {
            throw RazerError.writeFailed
        }
        usleep(50_000)
        var reply = [UInt8](repeating: 0, count: reportLength)
        var length = reply.count
        guard IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 0, &reply, &length) == kIOReturnSuccess else {
            throw RazerError.readFailed
        }
        guard reply[0] == 0x02 else { throw RazerError.refused(status: reply[0]) }
    }
}

enum RazerError: Error, CustomStringConvertible {
    case notConnected, needsInputMonitoring, writeFailed, readFailed
    case refused(status: UInt8)

    var description: String {
        switch self {
        case .notConnected: return "Razer Cobra not found. Is it plugged in?"
        case .needsInputMonitoring:
            return "Allow \(App.name) under System Settings > Privacy & Security > Input Monitoring, then reopen it."
        case .writeFailed: return "Couldn't send to the mouse."
        case .readFailed: return "Couldn't read the mouse's reply."
        case .refused(let status): return "The mouse refused the command (status \(status))."
        }
    }
}
