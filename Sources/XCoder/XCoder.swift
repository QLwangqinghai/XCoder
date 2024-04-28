
import Foundation

public struct XCoder {
    public static let domain = String(cString: XCoderErrorDomain)
    public static let countMax: UInt64 = UInt64.max >> 8
    
    public static let contentError: NSError = error(code: XCErrorContent)
    public static let typeError: NSError = error(code: XCErrorType)
    public static let notEnoughError: NSError = error(code: XCErrorNotEnough)
    public static let stringContentError: NSError = error(code: XCErrorStringContent)
    public static let numberOutOfBoundsError: NSError = error(code: XCErrorNumberOutOfBounds)
    
    public static func error(code: XCError_e) -> NSError {
        return NSError(domain: domain, code: Int(code.rawValue))
    }
    
    public static func encode(jsonMap: [String : Any?]) throws -> Data {
        let writer = XCWriter(minimumCapacity: 0)
        return try writer.writeMap(jsonMap)
    }
    public static func encode(jsonArray: [Any?]) throws -> Data {
        let writer = XCWriter(minimumCapacity: 0)
        return try writer.writeArray(jsonArray)
    }
}

public enum XCodingKey {
    case messageField(UInt64)
    case arrayIndex(Int)
    case mapIndex(Int)
    case setIndex(Int)
    case top
    case mapKey
    case mapValue
}


//
//public class XDecoderImpl {
//
//    public var offset: Int
//    public let endIndex: Int
//    public let data: NSData
//    public let bytes: UnsafePointer<UInt8>
//    let a: Decoder
//    public init(offset: Int = 0, data: NSData, endIndex: Int? = nil) {
//        let dec = JSONDecoder()
//
////        /// The path of coding keys taken to get to this point in decoding.
////        var codingPath: [CodingKey] { get }
////
////        /// Any contextual information set by the user for decoding.
////        var userInfo: [CodingUserInfoKey : Any] { get }
////
////        /// Returns the data stored in this decoder as represented in a container
////        /// keyed by the given key type.
////        ///
////        /// - parameter type: The key type to use for the container.
////        /// - returns: A keyed decoding container view into this decoder.
////        /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
////        ///   not a keyed container.
////        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey
////
////        /// Returns the data stored in this decoder as represented in a container
////        /// appropriate for holding values with no keys.
////        ///
////        /// - returns: An unkeyed container view into this decoder.
////        /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
////        ///   not an unkeyed container.
////        func unkeyedContainer() throws -> UnkeyedDecodingContainer
////
////        /// Returns the data stored in this decoder as represented in a container
////        /// appropriate for holding a single primitive value.
////        ///
////        /// - returns: A single value container view into this decoder.
////        /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
////        ///   not a single value container.
////        func singleValueContainer() throws -> SingleValueDecodingContainer
//
//
//        self.offset = offset
//        self.data = data
//        self.bytes = data.bytes.bindMemory(to: UInt8.self, capacity: data.count)
//        if let endIndex = endIndex {
//            self.endIndex = min(endIndex, data.endIndex)
//        } else {
//            self.endIndex = data.endIndex
//        }
//    }
//
//    public func read(_ closure: () -> XCError_e) throws {
//        let value = closure()
//        if value != XCErrorNone {
//            throw XCoder.error(code: value)
//        }
//    }
//    private func readHeader(index: UnsafeMutablePointer<Int>) throws -> XCValueHeader_s {
//        var header = XCValueHeaderMake()
//        let error = XCDecodeHeader(self.bytes, self.endIndex, index, &header)
//        guard error == XCErrorNone else {
//            throw XCoder.error(code: error)
//        }
//        return header
//    }
//    private func readMessageFieldOffset(index: UnsafeMutablePointer<Int>) throws -> UInt64 {
//        var offset: UInt64 = 0
//        let error = XCDecodeFieldKeyOffset(self.bytes, self.endIndex, index, &offset)
//        guard error == XCErrorNone else {
//            throw XCoder.typeError
//        }
//        return offset
//    }
//
//    private func readValue(index: UnsafeMutablePointer<Int>) throws -> XCValue {
//        let header = try self.readHeader(index: index)
//        guard header.type >= 0 && header.type <= UInt8.max else {
//            throw XCoder.typeError
//        }
//        guard let type = XCType(rawValue: UInt8(clamping: header.type)) else {
//            throw XCoder.typeError
//        }
//        switch type {
//        case .nil:
//            return .nil
//        case .bool:
//            return .bool(header.value.boolValue)
//        case .string:
//            let length = header.value.count
//            guard index.pointee + length <= self.data.count else {
//                throw XCoder.notEnoughError
//            }
//            guard let string = NSString(bytes: self.bytes.advanced(by: index.pointee), length: length, encoding: String.Encoding.utf8.rawValue) as? String else {
//                throw XCoder.error(code: XCErrorStringContent)
//            }
//            index.pointee += length
//            return .string(string as NSString)
//        case .data:
//            let length = header.value.count
//            guard index.pointee + length <= self.data.count else {
//                throw XCoder.notEnoughError
//            }
//            let data = self.data.subdata(with: NSRange(location: index.pointee, length: length))
//            index.pointee += length
//            return .data(data as NSData)
//        case .array:
//            let count = header.value.count
//            var elements: [XCValue] = []
//            elements.reserveCapacity(count)
//            for _ in 0 ..< count {
//                let value = try self.readValue(index: index)
//                elements.append(value)
//            }
//            return .array(elements)
//        case .map:
//            let count = header.value.count
//            var map: XMap = XMap()
//            map.reserveCapacity(count)
//
//            for _ in 0 ..< count {
//                let key = try self.readValue(index: index)
//                let value = try self.readValue(index: index)
//                if let _ = map.updateValue(value, forKey: key) {
//                    throw XCoder.error(code: XCErrorMapContent)
//                }
//            }
//            return .map(map)
//        case .set:
//            let count = header.value.count
//            var set: XSet = XSet()
//            set.reserveCapacity(count)
//
//            for _ in 0 ..< count {
//                let key = try self.readValue(index: index)
//                if let _ = set.update(with: key) {
//                    throw XCoder.error(code: XCErrorSetContent)
//                }
//            }
//            return .set(set)
//        case .number:
//            let number = header.value.number
//            guard let n = NSNumber.number(xvalue: number) else {
//                throw XCoder.error(code: XCErrorNumberContent)
//            }
//            return .number(n)
//        case .timeval:
//            return .timeval(Timeval(value: header.value.timeval))
//        case .message:
//            let type = header.value.message.type
//            let count = header.value.message.count
//
//            var message = Message(type: type)
//            message.reserveCapacity(count)
//
//            var prev: UInt64 = 0
//            for _ in 0 ..< count {
//                let offset = try self.readMessageFieldOffset(index: index)
//                guard prev <= UInt64.max - offset else {
//                    throw XCoder.error(code: XCErrorMessageFieldKeyOffset)
//                }
//                let key = prev + offset
//                prev = key
//                let field = try self.readValue(index: index)
//                message[key] = field
//            }
//            guard message.count == count else {
//                throw XCoder.error(code: XCErrorMessageContent)
//            }
//            return .message(message)
//        }
//    }
//
//    public func readValue() throws -> XCValue? {
//        var index = 0
//        return try self.readValue(index: &index)
//    }
//}
//
//public protocol XSingleValueDecodingContainer {
//
//}
//
//
//public struct XDecoder {
//    public let codingPath: [XCodingKey]
//    public let core: XDecoderImpl
//
//    private init(core: XDecoderImpl, codingPath: [XCodingKey]) {
//        self.core = core
//        self.codingPath = codingPath
//    }
//
//    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : XDecodable {
//
//    }
//    public func encode<T>(_ value: T) throws -> Data where T : XEncodable {
//
//    }
//
//
//
//    //        /// keyed by the given key type.
//    //        ///
//    //        /// - parameter type: The key type to use for the container.
//    //        /// - returns: A keyed decoding container view into this decoder.
//    //        /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
//    //        ///   not a keyed container.
//    //        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey
//    //
//    //        /// Returns the data stored in this decoder as represented in a container
//    //        /// appropriate for holding values with no keys.
//    //        ///
//    //        /// - returns: An unkeyed container view into this decoder.
//    //        /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
//    //        ///   not an unkeyed container.
//    //        func unkeyedContainer() throws -> UnkeyedDecodingContainer
//    //
//    //        /// Returns the data stored in this decoder as represented in a container
//    //        /// appropriate for holding a single primitive value.
//    //        ///
//    //        /// - returns: A single value container view into this decoder.
//    //        /// - throws: `DecodingError.typeMismatch` if the encountered stored value is
//    //        ///   not a single value container.
//    //        func singleValueContainer() throws -> SingleValueDecodingContainer
//
//
//    public func encodeNil() throws {
//
//
//    }
//
//    public func encodeBool(_ value: Bool) throws {
//
//
//    }
//    public func encodeNumber(_ value: NSNumber) throws {
//
//
//    }
//    public func encodeTimeval(_ value: Timeval) throws {
//
//
//    }
//    public func encodeString(_ value: NSString) throws {
//
//
//    }
//    public func encodeData(_ value: NSData) throws {
//
//
//    }
//    public func encodeArray(count: Int, coding: (XArrayEncodingContainer) throws -> Void) throws {
//        do {
//
//
//        } catch let error {
//            throw error
//        }
//        throw NSError(domain: XCoder.domain, code: Int(XCErrorType.rawValue))
//    }
//    public func encodeMap(count: Int, coding: (XMapEncodingContainer) throws -> Void) throws {
//
//    }
//    public func encodeSet(count: Int, coding: (XSetEncodingContainer) throws -> Void) throws {
//
//    }
//    public func encodeMessage(count: Int, messageType: UInt64, coding: (XMessageEncodingContainer) throws -> Void) throws {
//
//    }
//
//
//}
//
//
//func next24(container: XMessageDecodingContainer) throws {
////    do {
////        var iter = try container.next()
////
////        while let field = iter,  {
////            if field.0 < 13 {
////
////            }
////
////
////        }
////
////    } catch let error {
////        throw error
////    }
////
////
//}
//
//public protocol XMessageDecodingContainer {
//    func next() throws -> (UInt64, Codable)?
//}
//public protocol XArrayDecodingContainer {
//
//}
//public protocol XSetDecodingContainer {
//
//}
//public protocol XMapDecodingContainer {
//
//}
//
//
//
//public protocol XEncodingContainer {
//    var parent: XEncodingContainer? { get }
//    var key: XCodingKey { get }
//    var userInfo: [AnyHashable : Any] { get }
//}
//
//extension XEncodingContainer {
//    public var codingPath: [XCodingKey] {
//        var result: [XCodingKey] = [self.key]
//        while let parent = self.parent {
//            result.insert(parent.key, at: 0)
//        }
//        return result
//    }
//}
//
//public protocol XEncoder : XEncodingContainer {
//    mutating func encodeSingleValue(_ coding: (XSingleValueEncodingContainer) throws -> Void) throws
//    mutating func encodeArray(count: Int, coding: (XArrayEncodingContainer) throws -> Void) throws
//    mutating func encodeMap(count: Int, coding: (XMapEncodingContainer) throws -> Void) throws
//    mutating func encodeSet(count: Int, coding: (XSetEncodingContainer) throws -> Void) throws
//    mutating func encodeMessage(count: Int, messageType: UInt64, coding: (XMessageEncodingContainer) throws -> Void) throws
//}
//
//public protocol XSingleValueEncodingContainer : XEncodingContainer {
//    mutating func encodeNil() throws
//    mutating func encodeBool(_ value: Bool) throws
//    mutating func encodeNumber(_ value: NSNumber) throws
//    mutating func encodeTimeval(_ value: Timeval) throws
//    mutating func encodeString(_ value: NSString) throws
//    mutating func encodeData(_ value: NSData) throws
//}
//public protocol XMessageEncodingContainer : XEncodingContainer {
//    mutating func encodeElement(key: UInt64, coding: (XEncoder) throws -> Void) throws
//}
//public protocol XArrayEncodingContainer : XEncodingContainer {
//    mutating func encodeElement(_ coding: (XEncoder) throws -> Void) throws
//}
//public protocol XSetEncodingContainer : XEncodingContainer {
//    mutating func encodeElement(_ coding: (XEncoder) throws -> Void) throws
//}
//public protocol XMapEncodingContainer : XEncodingContainer {
//    mutating func encodeElement(keyCoding: (XEncoder) throws -> Void, valueCoding: (XEncoder) throws -> Void) throws
//}
//
//public struct XEncoder2 {
//    public var count: Int = 0
//    private var capacity: Int
//
//    public init() {
//        self.capacity = 1
//    }
//
//    public init(capacity: Int) {
//        self.capacity = capacity
//    }
//
//    public func encodeNil() throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//    }
//
//    public func encodeBool(_ value: Bool) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//    }
//    public func encodeNumber(_ value: NSNumber) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//    }
//    public func encodeTimeval(_ value: Timeval) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//    }
//    public func encodeString(_ value: NSString) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//    }
//    public func encodeData(_ value: NSData) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//    }
//
//    public mutating func encodeSingleValue(_ coding: (XSingleValueEncodingContainer) throws -> Void) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//        do {
//
//
//        } catch let error {
//            throw error
//        }
//        throw NSError(domain: XCoder.domain, code: Int(XCErrorType.rawValue))
//    }
//
//    public mutating func encodeArray(count: Int, coding: (XArrayEncodingContainer) throws -> Void) throws {
//        do {
//
//
//        } catch let error {
//            throw error
//        }
//        throw NSError(domain: XCoder.domain, code: Int(XCErrorType.rawValue))
//    }
//    public mutating func encodeMap(count: Int, coding: (XMapEncodingContainer) throws -> Void) throws {
//
//    }
//    public mutating func encodeSet(count: Int, coding: (XSetEncodingContainer) throws -> Void) throws {
//
//    }
//    public mutating func encodeMessage(count: Int, messageType: UInt64, coding: (XMessageEncodingContainer) throws -> Void) throws {
//
//    }
//    public mutating func encode(_ value: XCValue) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//    }
//}
//
//
//public class XCoreEncoder {
//    public struct Element {
//        public let key: XCodingKey
//        public let capacity: Int
//        public var count: Int = 0
//        public init(key: XCodingKey, capacity: Int) {
//            self.key = key
//            self.capacity = capacity
//        }
//    }
//
//    public private(set) var stack: [Element] = []
//
//    public init() {}
//
//    public func push(key: XCodingKey, capacity: Int) {
//
//    }
//
//    public func add() throws {
//        guard !self.stack.isEmpty else {
//            throw XCoder.contentError
//        }
//        let index = self.stack.count - 1
//        guard self.stack[index].capacity > self.stack[index].count else {
//            throw XCoder.contentError
//        }
//        self.stack[index].count += 1
//    }
//
//    public func pop() {
//
//    }
//
//}
//
//public struct XEncoderImpl: XEncoder {
//    public let parent: XEncodingContainer?
//    public let key: XCodingKey
//    let core: XCoreEncoder
//    public let userInfo: [AnyHashable : Any]
//
//    public var count: Int = 0
//    var capacity: Int {
//        return 1
//    }
//
//    init(userInfo: [AnyHashable : Any]) {
//        self.core = XCWriter(minimumCapacity: 0)
//        self.key = .top
//        self.userInfo = userInfo
//        self.parent = nil
//    }
//    init(core: XCoreEncoder, parent: XEncodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any]) {
//        self.core = core
//        self.parent = parent
//        self.key = key
//        self.userInfo = userInfo
//    }
//
//    public mutating func encodeSingleValue(_ coding: (XSingleValueEncodingContainer) throws -> Void) throws {
//        let coder = XSingleValueEncodingContainerImpl(core: self.core, parent: self.parent, key: self.key, userInfo: self.userInfo)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//    }
//    public mutating func encodeArray(count: Int, coding: (XArrayEncodingContainer) throws -> Void) throws {
////        self.core.write
//        let coder = XArrayEncodingContainerImpl(core: self.core, parent: self.parent, key: self.key, userInfo: self.userInfo, capacity: self.count)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//    }
//    public mutating func encodeMap(count: Int, coding: (XMapEncodingContainer) throws -> Void) throws {
//        let coder = XMapEncodingContainerImpl(core: self.core, parent: self.parent, key: self.key, userInfo: self.userInfo, capacity: self.count)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//    }
//    public mutating func encodeSet(count: Int, coding: (XSetEncodingContainer) throws -> Void) throws {
//        let coder = XSetEncodingContainerImpl(core: self.core, parent: self.parent, key: self.key, userInfo: self.userInfo, capacity: self.count)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//    }
//    public mutating func encodeMessage(count: Int, messageType: UInt64, coding: (XMessageEncodingContainer) throws -> Void) throws {
//        let coder = XMessageEncodingContainerImpl(core: self.core, parent: self.parent, key: self.key, userInfo: self.userInfo, capacity: self.count)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//    }
//}
//
//
//public struct XSingleValueEncodingContainerImpl : XSingleValueEncodingContainer {
//
//    public let parent: XEncodingContainer?
//    public let key: XCodingKey
//    let core: XCWriter
//    public let userInfo: [AnyHashable : Any]
//
//    public var count: Int = 0
//    var capacity: Int {
//        return 1
//    }
//    init(core: XCWriter, parent: XEncodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any]) {
//        self.core = core
//        self.parent = parent
//        self.key = key
//        self.userInfo = userInfo
//    }
//
//    public mutating func encodeNil() throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//        self.count += 1
//    }
//
//    public mutating func encodeBool(_ value: Bool) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//        self.count += 1
//    }
//    public mutating func encodeNumber(_ value: NSNumber) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//        self.count += 1
//    }
//    public mutating func encodeTimeval(_ value: Timeval) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//        self.count += 1
//    }
//    public mutating func encodeString(_ value: NSString) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//        self.count += 1
//    }
//    public mutating func encodeData(_ value: NSData) throws {
//        guard self.capacity > self.count else {
//            throw XCoder.contentError
//        }
//
//        self.count += 1
//    }
//}
//public struct XMessageEncodingContainerImpl : XMessageEncodingContainer {
//    public let parent: XEncodingContainer?
//    public let key: XCodingKey
//    let core: XCWriter
//    public let userInfo: [AnyHashable : Any]
//
//    public var count: Int = 0
//    var capacity: Int
//    init(core: XCWriter, parent: XEncodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any], capacity: Int) {
//        self.core = core
//        self.parent = parent
//        self.key = key
//        self.userInfo = userInfo
//        self.capacity = capacity
//    }
//    public mutating func encodeElement(key: UInt64, coding: (XEncoder) throws -> Void) throws {
//        let coder = XEncoderImpl(core: self.core, parent: self, key: .messageField(key), userInfo: self.userInfo)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//    }
//
//}
//public struct XArrayEncodingContainerImpl : XArrayEncodingContainer {
//
//    public let parent: XEncodingContainer?
//    public let key: XCodingKey
//    let core: XCWriter
//    public let userInfo: [AnyHashable : Any]
//
//    public var count: Int = 0
//    var capacity: Int
//    init(core: XCWriter, parent: XEncodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any], capacity: Int ) {
//        self.core = core
//        self.parent = parent
//        self.key = key
//        self.userInfo = userInfo
//        self.capacity = capacity
//    }
//    public mutating func encodeElement(_ coding: (XEncoder) throws -> Void) throws {
//        let coder = XEncoderImpl(core: self.core, parent: self, key: .arrayIndex(self.count), userInfo: self.userInfo)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//    }
//}
//public struct XSetEncodingContainerImpl : XSetEncodingContainer {
//
//    public let parent: XEncodingContainer?
//    public let key: XCodingKey
//    let core: XCWriter
//    public let userInfo: [AnyHashable : Any]
//
//    public var count: Int = 0
//    var capacity: Int
//    init(core: XCWriter, parent: XEncodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any], capacity: Int ) {
//        self.core = core
//        self.parent = parent
//        self.key = key
//        self.userInfo = userInfo
//        self.capacity = capacity
//    }
//
//    public mutating func encodeElement(_ coding: (XEncoder) throws -> Void) throws {
//        let coder = XEncoderImpl(core: self.core, parent: self, key: .setIndex(self.count), userInfo: self.userInfo)
//        do {
//            try coding(coder)
//            guard coder.count == coder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//        self.count += 1
//    }
//}
//public struct XMapEncodingContainerImpl : XMapEncodingContainer {
//    public let parent: XEncodingContainer?
//    public let key: XCodingKey
//    let core: XCWriter
//    public let userInfo: [AnyHashable : Any]
//
//    public var count: Int = 0
//    var capacity: Int
//    init(core: XCWriter, parent: XEncodingContainer?, key: XCodingKey, userInfo: [AnyHashable : Any], capacity: Int ) {
//        self.core = core
//        self.parent = parent
//        self.key = key
//        self.userInfo = userInfo
//        self.capacity = capacity
//    }
//
//
//    public mutating func encodeElement(keyCoding: (inout XEncoder) throws -> Void, valueCoding: (inout XEncoder) throws -> Void) throws {
//        var keyCoder = XEncoderImpl(core: self.core, parent: self, key: .mapIndex(self.count), userInfo: self.userInfo)
//        var valueCoder = XEncoderImpl(core: self.core, parent: self, key: .mapIndex(self.count), userInfo: self.userInfo)
//        do {
//            try keyCoding(keyCoder)
//            guard keyCoder.count == keyCoder.capacity else {
//                throw XCoder.contentError
//            }
//            try valueCoding(valueCoder as any XEncoder)
//            guard valueCoder.count == valueCoder.capacity else {
//                throw XCoder.contentError
//            }
//        } catch let error {
//            throw error
//        }
//        self.count += 1
//    }
//
//
//}
//
////extension XDecodable {
////
////    public static func xdecode(context: [AnyHashable : Any]) throws -> Self {
////
////
////    }
////
////}
////extension XEncodable {
////
////    public static func xencode(context: [AnyHashable : Any]) throws -> Self {
////
////
////    }
////
////}
//public protocol XMessageDecodable {
//
//    static func xdecode(decoder: XDecoder) throws -> Self
//
//}
//public protocol XMessageEncodable {
//
//    func xencode(encoder: XDecoder) throws
//
//}
//public typealias XMessageCodable = XMessageDecodable & XMessageEncodable
//
//
//public protocol XDecodable {
//
//    static func xdecode(decoder: XDecoder) throws -> Self
//
//}
//
//public protocol XEncodable {
//
//    static func xencode(encoder: XDecoder) throws -> Self
//
//}
//public typealias XCodable = XDecodable & XEncodable
