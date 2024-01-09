import Foundation
import IOKit
import IOKit.usb

struct USBEvent: Codable {
    var eventType: String
    var timestamp: String
    var deviceInfo: [String: String]

    init(eventType: String, deviceInfo: [String: String]) {
        self.eventType = eventType
        self.deviceInfo = deviceInfo
        self.timestamp = USBEvent.currentLocalTimestamp()
    }

    private static func currentLocalTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ" // Updated format
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}

var usbVendorProductMap = [String: [String: String]]()

func parseUSBIDs(from filePath: String) {
    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        var currentVendorID: String?
        for line in content.split(whereSeparator: \.isNewline) {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") { continue }

            if line.first!.isNumber {
                let components = trimmedLine.split(separator: " ", maxSplits: 1)
                if components.count == 2 {
                    currentVendorID = String(components[0])
                    let vendorName = String(components[1])
                    usbVendorProductMap[currentVendorID!] = ["": vendorName]  // Vendor name
                }
            } else if line.first == "\t", let vendorID = currentVendorID {
                let components = trimmedLine.split(separator: " ", maxSplits: 1)
                if components.count == 2 {
                    let productID = String(components[0])
                    let productName = String(components[1])
                    usbVendorProductMap[vendorID]?[productID] = productName
                }
            }
        }
    } catch {
        print("Failed to read or parse USB IDs file: \(error)")
    }
}

func logUSBEvent(event: USBEvent, to filePath: String) {
    let encoder = JSONEncoder()
    if let jsonData = try? encoder.encode(event), let jsonString = String(data: jsonData, encoding: .utf8) {
        do {
            try jsonString.appendLineToURL(fileURL: URL(fileURLWithPath: filePath))
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
}

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToFile(fileURL: fileURL)
    }

    func appendToFile(fileURL: URL) throws {
        let data = self.data(using: .utf8)!
        try data.append(fileURL: fileURL)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

func extractDeviceInfo(device: io_object_t) -> [String: String] {
    var deviceInfo = [String: String]()
    let vendorIDKey = kUSBVendorID as String
    let productIDKey = kUSBProductID as String
    let serialNumberKey = kUSBSerialNumberString as String

    if let vendorIDRef = IORegistryEntrySearchCFProperty(device, kIOServicePlane, vendorIDKey as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)),
       CFGetTypeID(vendorIDRef) == CFNumberGetTypeID() {
        var vendorID: Int = 0
        CFNumberGetValue((vendorIDRef as! CFNumber), CFNumberType.intType, &vendorID)
        let hexVendorID = String(format: "%04x", vendorID)
        deviceInfo[vendorIDKey] = hexVendorID
        if let vendorName = usbVendorProductMap[hexVendorID]?[""] {
            deviceInfo["vendorName"] = vendorName
        }
    }

    if let productIDRef = IORegistryEntrySearchCFProperty(device, kIOServicePlane, productIDKey as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)),
       CFGetTypeID(productIDRef) == CFNumberGetTypeID() {
        var productID: Int = 0
        CFNumberGetValue((productIDRef as! CFNumber), CFNumberType.intType, &productID)
        let hexProductID = String(format: "%04x", productID)
        deviceInfo[productIDKey] = hexProductID
        if let vendorID = deviceInfo[vendorIDKey],
           let productName = usbVendorProductMap[vendorID]?[hexProductID] {
            deviceInfo["productName"] = productName
        }
    }

    if let serialNumberRef = IORegistryEntrySearchCFProperty(device, kIOServicePlane, serialNumberKey as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) as? String {
        deviceInfo[serialNumberKey] = serialNumberRef
    }

    // Debug: Print the mapping results including Serial Number
    print("Mapped Vendor ID: \(deviceInfo[vendorIDKey] ?? "Not Found")")
    print("Mapped Product ID: \(deviceInfo[productIDKey] ?? "Not Found")")
    print("Mapped Serial Number: \(deviceInfo[serialNumberKey] ?? "Not Found")")
    print("Mapped Vendor Name: \(deviceInfo["vendorName"] ?? "Not Found")")
    print("Mapped Product Name: \(deviceInfo["productName"] ?? "Not Found")")
    
    return deviceInfo
}

func usbDeviceCallback(context: UnsafeMutableRawPointer?, iterator: io_iterator_t, eventType: String) {
    var device: io_object_t
    repeat {
        device = IOIteratorNext(iterator)
        if device != 0 {
            let deviceInfo = extractDeviceInfo(device: device)
            let event = USBEvent(
                eventType: eventType,
                deviceInfo: deviceInfo
            )
            logUSBEvent(event: event, to: "/var/log/usb_monitor.log")
            IOObjectRelease(device)
        }
    } while device != 0
}

let notifyPort = IONotificationPortCreate(kIOMainPortDefault)
let runLoopSource = IONotificationPortGetRunLoopSource(notifyPort).takeRetainedValue()
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.defaultMode)

let scriptPath = URL(fileURLWithPath: #file).deletingLastPathComponent().path
parseUSBIDs(from: "/path/to/usb.ids")

var deviceAddedIter = io_iterator_t()
var deviceRemovedIter = io_iterator_t()

let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, matchingDict, { (context, iterator) in
    usbDeviceCallback(context: context, iterator: iterator, eventType: "USBConnected")
}, nil, &deviceAddedIter)
usbDeviceCallback(context: nil, iterator: deviceAddedIter, eventType: "USBConnected")

IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matchingDict, { (context, iterator) in
    usbDeviceCallback(context: context, iterator: iterator, eventType: "USBDisconnected")
}, nil, &deviceRemovedIter)
usbDeviceCallback(context: nil, iterator: deviceRemovedIter, eventType: "USBDisconnected")

CFRunLoopRun()
