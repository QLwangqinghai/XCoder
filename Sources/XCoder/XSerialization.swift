
import Foundation

public struct XSerialization {
    
    public static func decode(data: Data) throws -> XCValue? {
        guard !data.isEmpty else {
            return nil
        }
        let reader = XCReader(data: data as NSData)
        return try reader.readValue()
    }

    public static func encode(value: XCValue) throws -> Data {
        let writer = XCWriter(minimumCapacity: 0)
        return try writer.writeValue(value)
    }

}

public class XCReader {
    public var offset: Int
    public let endIndex: Int
    public let data: NSData
    public let bytes: UnsafePointer<UInt8>

    public init(offset: Int = 0, data: NSData, endIndex: Int? = nil) {
        self.offset = offset
        self.data = data
        self.bytes = data.bytes.bindMemory(to: UInt8.self, capacity: data.count)
        if let endIndex = endIndex {
            self.endIndex = min(endIndex, data.endIndex)
        } else {
            self.endIndex = data.endIndex
        }
    }
    
    public func read(_ closure: () -> XCError_e) throws {
        let value = closure()
        if value != XCErrorNone {
            throw XCoder.error(code: value)
        }
    }
    private func readHeader(index: UnsafeMutablePointer<Int>) throws -> XCValueHeader_s {
        var header = XCValueHeaderMake()
        let error = XCDecodeHeader(self.bytes, self.endIndex, index, &header)
        guard error == XCErrorNone else {
            throw XCoder.error(code: error)
        }
        return header
    }
    private func readMessageFieldOffset(index: UnsafeMutablePointer<Int>) throws -> Int64 {
        var offset: Int64 = 0
        let error = XCDecodeFieldKeyOffset(self.bytes, self.endIndex, index, &offset)
        guard error == XCErrorNone else {
            throw XCoder.typeError
        }
        return offset
    }
    
    private func readValue(index: UnsafeMutablePointer<Int>) throws -> XCValue {
        let header = try self.readHeader(index: index)
        guard header.type >= 0 && header.type <= UInt8.max else {
            throw XCoder.typeError
        }
        guard let type = XCType(rawValue: UInt8(clamping: header.type)) else {
            throw XCoder.typeError
        }
        switch type {
        case .nil:
            return .nil
        case .bool:
            return .bool(header.value.boolValue)
        case .string:
            let length = header.value.count
            guard index.pointee + length <= self.data.count else {
                throw XCoder.notEnoughError
            }
            guard let string = NSString(bytes: self.bytes.advanced(by: index.pointee), length: length, encoding: String.Encoding.utf8.rawValue) as? String else {
                throw XCoder.stringContentError
            }
            index.pointee += length
            return .string(string as NSString)
        case .data:
            let length = header.value.count
            guard index.pointee + length <= self.data.count else {
                throw XCoder.notEnoughError
            }
            let data = self.data.subdata(with: NSRange(location: index.pointee, length: length))
            index.pointee += length
            return .data(data as NSData)
        case .array:
            let count = header.value.count
            var elements: [XCValue] = []
            elements.reserveCapacity(count)
            for _ in 0 ..< count {
                let value = try self.readValue(index: index)
                elements.append(value)
            }
            return .array(elements)
        case .map:
            let count = header.value.count
            var map: XMap = XMap()
            map.reserveCapacity(count)
            
            for _ in 0 ..< count {
                let key = try self.readValue(index: index)
                let value = try self.readValue(index: index)
                if let _ = map.updateValue(value, forKey: key) {
                    throw XCoder.error(code: XCErrorMapContent)
                }
            }
//            print("dict: \(m2)")
            return .map(map)
        case .set:
            let count = header.value.count
            var set: XSet = XSet()
            set.reserveCapacity(count)

            for _ in 0 ..< count {
                let key = try self.readValue(index: index)
                if let _ = set.update(with: key) {
                    throw XCoder.error(code: XCErrorSetContent)
                }
            }
            return .set(set)
        case .number:
            let number = header.value.number
            guard let n = NSNumber.number(xvalue: number) else {
                throw XCoder.error(code: XCErrorNumberContent)
            }
            return .number(n)
        case .timeval:
            return .timeval(Timeval(value: header.value.timeval))
        case .message:
            let type = header.value.message.type
            let count = header.value.message.count

            var prev: Int64 = 0
            var collection: [Int64 : XCValue] = [:]
            collection.reserveCapacity(count)
            for _ in 0 ..< count {
                let offset = try self.readMessageFieldOffset(index: index)
                guard prev <= Int64.max - offset else {
                    throw XCoder.error(code: XCErrorMessageFieldKeyOffset)
                }
                let key = prev + offset
                prev = key
                let field = try self.readValue(index: index)
                collection[key] = field
            }
            guard collection.count == count else {
                throw XCoder.error(code: XCErrorMessageContent)
            }
            return .message(Message(type: type, collection: collection))
        }
    }
    
    public func readValue() throws -> XCValue? {
        var index = 0
        return try self.readValue(index: &index)
    }
}

public class XCWriter {
    public var count: Int = 0
    private var capacity: Int
    private var _bytes: UnsafeMutableRawPointer
    
    public var bytes: UnsafeMutablePointer<UInt8> {
        return self._bytes.bindMemory(to: UInt8.self, capacity: self.capacity)
    }
    
    public init(minimumCapacity: Int) {
        let value = XCWriter.capacityAlign(minimumCapacity)
        self.capacity = value
        self._bytes = realloc(nil, value)
    }
    
    public func reserveCapacity(_ minimumCapacity: Int) {
        guard minimumCapacity >= self.capacity else {
            return
        }
        let value = XCWriter.capacityAlign(minimumCapacity)
        guard self.capacity != value else {
            return
        }
        self._bytes = realloc(self._bytes, value)
        self.capacity = value
    }
    deinit {
        free(self._bytes)
    }
    
    private static func capacityAlign(_ minimumCapacity: Int) -> Int {
        var value = max(0x1000, minimumCapacity)
        if value.leadingZeroBitCount + value.trailingZeroBitCount != value.bitWidth - 1 {
            value = 1 << (value.bitWidth - value.leadingZeroBitCount)
        }
        if value >= 0x200000 {
            value = (value + 0x200000 - 1) / 0x200000 * 0x200000
        } else {
            value = (value + 0x1000 - 1) / 0x1000 * 0x1000
        }
        return value
    }
    
    public func write(_ closure: () -> XCError_e) throws {
        let value = closure()
        if value != XCErrorNone {
            throw NSError(domain: XCoder.domain, code: Int(value.rawValue))
        }
    }
    
    private func _writeValue(_ value: XCValue) throws {
        if self.count + XCHeaderMaxLength() > self.capacity {
            self.reserveCapacity(self.count + XCHeaderMaxLength())
        }
        switch value {
        case .nil:
            try self.write({
                return XCEncodeNil(self.bytes, self.capacity, &self.count)
            })
        case .bool(let v):
            try self.write({
                return XCEncodeBool(self.bytes, self.capacity, &self.count, v)
            })
        case .string(let _v):
            let v = _v as String
            guard let data = v.data(using: .utf8) else {
                throw XCoder.error(code: XCErrorStringContent)
            }
            try self.write({
                return XCEncodeStringHeader(self.bytes, self.capacity, &self.count, data.count)
            })
            if self.count + data.count > self.capacity {
                self.reserveCapacity(self.count + data.count)
            }
            if !data.isEmpty {
                try self.write({
                    return data.withUnsafeBytes { ptr in
                        return XCEncodeBody(self.bytes, self.capacity, &self.count, ptr.baseAddress!, data.count)
                    }
                })
            }
        case .data(let data):
            try self.write({
                return XCEncodeDataHeader(self.bytes, self.capacity, &self.count, data.count)
            })
            if self.count + data.count > self.capacity {
                self.reserveCapacity(self.count + data.count)
            }
            if !data.isEmpty {
                try self.write({
                    return XCEncodeBody(self.bytes, self.capacity, &self.count, data.bytes, data.count)
                })
            }
        case .array(let array):
            try self.write({
                return XCEncodeArrayHeader(self.bytes, self.capacity, &self.count, array.count)
            })
            if self.count + array.count > self.capacity {
                self.reserveCapacity(self.count + array.count)
            }
            try array.forEach { item in
                try self._writeValue(item)
            }
        case .map(let map):
            try self.write({
                return XCEncodeOrderedMapHeader(self.bytes, self.capacity, &self.count, map.count)
            })
            if self.count + map.count * 2 > self.capacity {
                self.reserveCapacity(self.count + map.count * 2)
            }
            try map.forEach { (key, value) in
                try self._writeValue(key)
                try self._writeValue(value)
            }
        case .set(let set):
            try self.write({
                return XCEncodeOrderedSetHeader(self.bytes, self.capacity, &self.count, set.count)
            })
            if self.count + set.count > self.capacity {
                self.reserveCapacity(self.count + set.count)
            }
            try set.forEach { key in
                try self._writeValue(key)
            }
        case .number(let v):
            if let value = v as? Double {
                try self.write({
                    return XCEncodeNumberDouble(self.bytes, self.capacity, &self.count, value)
                })
            } else if let value = v as? Int64 {
                try self.write({
                    return XCEncodeNumberSInt64(self.bytes, self.capacity, &self.count, value)
                })
            } else if let value = v as? UInt64 {
                try self.write({
                    return XCEncodeNumberUInt64(self.bytes, self.capacity, &self.count, value)
                })
            } else {
                throw XCoder.error(code: XCErrorNumberContent)
            }
        case .timeval(let v):
            try self.write({
                return XCEncodeTimeval(self.bytes, self.capacity, &self.count, v.value)
            })
        case .message(let message):
            try self.write({
                return XCEncodeMessageHeader(self.bytes, self.capacity, &self.count, message.collection.count, message.type)
            })
            if self.count + message.collection.count * 2 > self.capacity {
                self.reserveCapacity(self.count + message.collection.count * 2)
            }
            var elements = message.collection.map { e in
                return e
            }
            elements.sort { lhs, rhs in
                return lhs.0 < rhs.0
            }
            var prev: Int64 = 0
            try elements.forEach { (key, value) in
                if self.count + 10 > self.capacity {
                    self.reserveCapacity(self.count + 10)
                }
                try self.write({
                    return XCEncodeFieldKeyOffset(self.bytes, self.capacity, &self.count, key - prev)
                })
                prev = key
                try self._writeValue(value)
            }
        }
    }
    
    private func _writeJsonValue(_ value: Any?) throws {
        guard let value = value else {
            try _writeValue(.nil)
            return
        }
        if let v = value as? NSNumber {
            let n = v as CFNumber
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
                try _writeValue(.bool(v.boolValue))
            } else {
                try _writeValue(.number(v))
            }
        } else if let v = value as? String {
            try _writeValue(.string(v as NSString))
        } else if let v = value as? [Any] {
            try _writeArray(v)
        } else if let v = value as? [String : Any] {
            try _writeMap(v)
        } else {
            throw XCoder.typeError
        }
    }
    private func _writeArray(_ array: [Any?]) throws {
        try self.write({
            return XCEncodeArrayHeader(self.bytes, self.capacity, &self.count, array.count)
        })
        if self.count + array.count > self.capacity {
            self.reserveCapacity(self.count + array.count)
        }
        try array.forEach { value in
            try _writeJsonValue(value)
        }
    }
    private func _writeMap(_ map: [String : Any?]) throws {
        try self.write({
            return XCEncodeOrderedMapHeader(self.bytes, self.capacity, &self.count, map.count)
        })
        if self.count + map.count * 2 > self.capacity {
            self.reserveCapacity(self.count + map.count * 2)
        }
        try map.forEach { (key, value) in
            try _writeValue(.string(key as NSString))
            try _writeJsonValue(value)
        }
    }
    
    public func writeArray(_ array: [Any?]) throws -> Data {
        try _writeArray(array)
        return Data(bytes: self._bytes, count: self.count)
    }
    public func writeMap(_ map: [String : Any?]) throws -> Data {
        try _writeMap(map)
        return Data(bytes: self._bytes, count: self.count)
    }
    
    public func writeValue(_ value: XCValue) throws -> Data {
        try _writeValue(value)
        return Data(bytes: self._bytes, count: self.count)
    }
}

