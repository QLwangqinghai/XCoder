
import Foundation

public enum XCValue : Hashable {
    case `nil`
    case bool(Bool)
    case string(NSString)
    case data(NSData)
    case array([XCValue])
    case map(OrderedMap<XCValue, XCValue>)
    case set(OrderedSet<XCValue>)
    
    case number(NSNumber)
    case timeval(Timeval)
    case message(Message)
    
    public func isNil() -> Bool {
        if case .nil = self {
            return true
        } else {
            return false
        }
    }
    
    public func boolValue() throws -> Bool {
        guard case .bool(let bool) = self else {
            throw XCoder.typeError
        }
        return bool
    }

    public func numberValue() throws -> NSNumber {
        guard case .number(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func timevalValue() throws -> Timeval {
        guard case .timeval(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func stringValue() throws -> NSString {
        guard case .string(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func dataValue() throws -> NSData {
        guard case .data(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func messageValue() throws -> Message {
        guard case .message(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func arrayValue() throws -> [XCValue] {
        guard case .array(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func mapValue() throws -> XMap {
        guard case .map(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func setValue() throws -> XSet {
        guard case .set(let value) = self else {
            throw XCoder.typeError
        }
        return value
    }
    
    public func doubleValue() throws -> Double {
        let v = try self.numberValue()
        guard let value = v as? Double else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func floatValue() throws -> Float {
        let v = try self.numberValue()
        guard let value = v as? Float else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func intValue() throws -> Int {
        let v = try self.numberValue()
        guard let value = v as? Int else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func uintValue() throws -> UInt {
        let v = try self.numberValue()
        guard let value = v as? UInt else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func int8Value() throws -> Int8 {
        let v = try self.numberValue()
        guard let value = v as? Int8 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint8Value() throws -> UInt8 {
        let v = try self.numberValue()
        guard let value = v as? UInt8 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }

    public func int16Value() throws -> Int16 {
        let v = try self.numberValue()
        guard let value = v as? Int16 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint16Value() throws -> UInt16 {
        let v = try self.numberValue()
        guard let value = v as? UInt16 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func int32Value() throws -> Int32 {
        let v = try self.numberValue()
        guard let value = v as? Int32 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint32Value() throws -> UInt32 {
        let v = try self.numberValue()
        guard let value = v as? UInt32 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func int64Value() throws -> Int64 {
        let v = try self.numberValue()
        guard let value = v as? Int64 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }
    
    public func uint64Value() throws -> UInt64 {
        let v = try self.numberValue()
        guard let value = v as? UInt64 else {
            throw XCoder.numberOutOfBoundsError
        }
        return value
    }

    public func value(_ type: Bool.Type) throws -> Bool {
        return try self.boolValue()
    }

    public func value(_ type: NSNumber.Type) throws -> NSNumber {
        return try self.numberValue()
    }
    
    public func value(_ type: Timeval.Type) throws -> Timeval {
        return try self.timevalValue()
    }
    
    public func value(_ type: NSString.Type) throws -> NSString {
        return try self.stringValue()
    }
    
    public func value(_ type: NSData.Type) throws -> NSData {
        return try self.dataValue()
    }
    
    public func value(_ type: Message.Type) throws -> Message {
        return try self.messageValue()
    }
}

public enum XCType : UInt8 {
    // payload 3
    case `nil` = 0
    case bool = 1
    case number = 2
    case timeval = 3
    case string = 4
    case data = 5
    case message = 6
    case array = 7
    case map = 8
    case set = 9
    
    public static let maxRawValue: UInt8 = 15
}

public struct Timeval : Hashable, Codable {
    public var value: Int64
    public init(value: Int64) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        self.value = try decoder.singleValueContainer().decode(Int64.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }
    
    public static func random() -> Timeval {
        return Timeval(value: Int64.random(in: Int64.min ... Int64.max))
    }
    public static func random(in range: ClosedRange<Int64>) -> Timeval {
        return Timeval(value: Int64.random(in: range))
    }
    
    public static let distantFuture = Timeval(value: Int64.max)
    public static let distantPast = Timeval(value: Int64.min)

}

public typealias XMap = OrderedMap<XCValue, XCValue>
public typealias XSet = OrderedSet<XCValue>

//public struct OrderedMap<Key, Value> : Hashable where Key : Hashable, Value : Hashable {
//    private let map: Dictionary<Key, Element<Key, Value>>
//    public let elements: [Element<Key, Value>]
//
//    public var count: Int {
//        return self.elements.count
//    }
//
//    public final class Element<Key, Value> : Equatable where Key : Hashable, Value : Hashable {
//        public static func == (lhs: Element<Key, Value>, rhs: Element<Key, Value>) -> Bool {
//            return lhs.key == rhs.key && lhs.value == rhs.value && lhs.index == rhs.index
//        }
//        public let index: Int
//        public let key: Key
//        public let value: Value
//        init(index: Int, key: Key, value: Value) {
//            self.key = key
//            self.value = value
//            self.index = index
//        }
//    }
//
//    public init<S>(uniqueKeysWithValues: S) where S : Sequence, S.Element == (Key, Value) {
//        let array = uniqueKeysWithValues.enumerated().map({ (index, keyValue) in
//            return Element(index: index, key: keyValue.0, value: keyValue.1)
//        })
//        let map = Dictionary(uniqueKeysWithValues: array.map({ element in
//            return (element.key, element)
//        }))
//        self.map = map
//        self.elements = array
//    }
//
//    public subscript(key: Key) -> Element<Key, Value>? {
//        get {
//            return self.map[key]
//        }
//    }
//
//    public func forEach(_ body: (Element<Key, Value>) throws -> Void) rethrows {
//        try self.elements.forEach(body)
//    }
//    public func map<T>(_ transform: (Element<Key, Value>) throws -> T) rethrows -> [T] {
//        return try self.elements.map(transform)
//    }
//
//    public static func == (lhs: OrderedMap<Key, Value>, rhs: OrderedMap<Key, Value>) -> Bool {
//        return lhs.elements == rhs.elements
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.elements.count)
//        // 最后4个elements
//        self.elements.reversed().prefix(4).forEach { element in
//            hasher.combine(element.key)
//        }
//    }
//}
//
//public struct OrderedSet<Key> : Hashable where Key : Hashable {
//    private let map: Dictionary<Key, Element<Key>>
//    public let elements: [Element<Key>]
//
//    public var count: Int {
//        return self.elements.count
//    }
//
//    public final class Element<Key> : Equatable where Key : Hashable {
//        public static func == (lhs: Element<Key>, rhs: Element<Key>) -> Bool {
//            return lhs.key == rhs.key && lhs.index == rhs.index
//        }
//        public let index: Int
//        public let key: Key
//        init(index: Int, key: Key) {
//            self.key = key
//            self.index = index
//        }
//    }
//    public init<S>(uniqueKeys: S) where S : Sequence, S.Element == Key {
//        let array = uniqueKeys.enumerated().map({ (index, key) in
//            return Element(index: index, key: key)
//        })
//        let map = Dictionary(uniqueKeysWithValues: array.map({ element in
//            return (element.key, element)
//        }))
//        self.map = map
//        self.elements = array
//    }
//
//    public subscript(key: Key) -> Element<Key>? {
//        get {
//            return self.map[key]
//        }
//    }
//
//    public func forEach(_ body: (Element<Key>) throws -> Void) rethrows {
//        try self.elements.forEach(body)
//    }
//    public func map<T>(_ transform: (Element<Key>) throws -> T) rethrows -> [T] {
//        return try self.elements.map(transform)
//    }
//
//    public static func == (lhs: OrderedSet<Key>, rhs: OrderedSet<Key>) -> Bool {
//        return lhs.elements == rhs.elements
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.elements.count)
//        // 最后4个elements
//        self.elements.reversed().prefix(4).forEach { element in
//            hasher.combine(element.key)
//        }
//    }
//}

public struct Message : Hashable {
    public var type: Int64
    public var collection: [Int64 : XCValue]
    public var count: Int {
        return self.collection.count
    }

    public init(type: Int64) {
        self.type = type
        self.collection = [:]
    }

    public init(type: Int64, collection: [Int64 : XCValue]) {
        self.type = type
        self.collection = collection
    }
    
    public subscript(key: Int64) -> XCValue? {
        get {
            return self.collection[key]
        }
        set {
            if let v = newValue {
                // setvalue
                _ = self.updateValue(v, forKey: key)
            } else {
                // removeValue
                self.collection.removeValue(forKey: key)
            }
        }
    }
    @discardableResult public mutating func updateValue(_ value: XCValue, forKey key: Int64) -> XCValue? {
        return self.collection.updateValue(value, forKey: key)
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.collection.reserveCapacity(minimumCapacity)
    }
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.type == rhs.type && lhs.collection == rhs.collection
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.type)
        hasher.combine(self.collection)
    }
}

public struct OrderedMap<Key, Value> : Hashable where Key : Hashable, Value: Equatable {
    public class Element<Key, Value> : Equatable where Key : Hashable, Value: Equatable {
        public static func == (lhs: Element<Key, Value>, rhs: Element<Key, Value>) -> Bool {
            return lhs.key == rhs.key && lhs.value == rhs.value
        }
        public let key: Key
        public let value: Value
        public init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    public private(set) var map: Dictionary<Key, Element<Key, Value>>
    
    /// The order of the first insertion
    public private(set) var array: [Element<Key, Value>]
    
    public var count: Int {
        return self.array.count
    }
    
    public init() {
        self.map = [:]
        self.array = []
    }
        
    public init<S>(uniqueKeysWithValues: S) where S : Sequence, S.Element == (Key, Value) {
        let array = uniqueKeysWithValues.map { (key, value) in
            return (key, Element(key: key, value: value))
        }
//        let array = uniqueKeysWithValues.map { (key, value) in
//            return Element(key: key, value: value)
//        }
        let map = Dictionary(uniqueKeysWithValues: array)
        self.map = map
        self.array = array.map({ element in
            return element.1
        })
    }
    public subscript(key: Key) -> Value? {
        get {
            return self.map[key]?.value
        }
        set {
            if let v = newValue {
                // setvalue
                _ = self.updateValue(v, forKey: key)
            } else {
                // removeValue
                if let _ = self.map.removeValue(forKey: key) {
                    let index = self.array.firstIndex(where: { element in
                        return element.key == key
                    })!
                    self.array.remove(at: index)
                }
            }
        }
    }

    public func forEach(_ body: (Key, Value) throws -> Void) rethrows {
        return try self.array.forEach({ element in
            try body(element.key, element.value)
        })
    }
    public func map<T>(_ transform: (Key, Value) throws -> T) rethrows -> [T] {
        return try self.array.map({ element in
            return try transform(element.key, element.value)
        })
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.map.reserveCapacity(minimumCapacity)
        self.array.reserveCapacity(minimumCapacity)
    }
    
    @discardableResult public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let element = Element(key: key, value: value)
        if let old = self.map.updateValue(element, forKey: key) {
            let index = self.array.firstIndex(where: { element in
                return element.key == key
            })!
            self.array[index] = element
            return old.value
        } else {
            self.array.append(element)
            return nil
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.array.count)
        // 最后4个elements
        self.array.reversed().prefix(4).forEach { element in
            hasher.combine(element.key)
        }
    }
    public static func == (lhs: OrderedMap<Key, Value>, rhs: OrderedMap<Key, Value>) -> Bool {
        return lhs.array == rhs.array
    }
}

public struct OrderedSet<Key> : Hashable where Key : Hashable {
    public private(set) var set: Set<Key>
    
    /// The order of the first insertion
    public private(set) var array: [Key]
    
    public var count: Int {
        return self.array.count
    }
    
    public init() {
        self.set = []
        self.array = []
    }
    
    public init<S>(uniqueKeys: S) where S : Sequence, S.Element == Key {
        let array = Array(uniqueKeys)
        let set = Set(array)
        assert(array.count == set.count)
        self.set = set
        self.array = array
    }

    public func contains(_ member: Key) -> Bool {
        return self.set.contains(member)
    }
    public mutating func update(with key: Key) -> Key? {
        if let v = self.set.update(with: key) {
            return v
        } else {
            self.array.append(key)
            return nil
        }
    }
    public mutating func insert(_ member: Key) {
        if !self.set.contains(member) {
            self.array.append(member)
            self.set.insert(member)
        }
    }
    @discardableResult public mutating func remove(_ member: Key) -> Key? {
        if let old = self.set.remove(member) {
            self.array.removeAll(where: { k in
                return k == member
            })
            return old
        }
        return nil
    }
    public func forEach(_ body: (Key) throws -> Void) rethrows {
        try self.array.forEach(body)
    }
    public func map<T>(_ transform: (Key) throws -> T) rethrows -> [T] {
        return try self.array.map(transform)
    }

    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        self.set.reserveCapacity(minimumCapacity)
        self.array.reserveCapacity(minimumCapacity)
    }
    
    public static func == (lhs: OrderedSet<Key>, rhs: OrderedSet<Key>) -> Bool {
        return lhs.array == rhs.array
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.array.count)
        // 最后4个elements
        self.array.reversed().prefix(4).forEach { key in
            hasher.combine(key)
        }
    }
}




public final class XBool : NSObject, NSCopying {
    public let value: Bool
    
    private init(_ value: Bool) {
        self.value = value
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override func isEqual(to object: Any?) -> Bool {
        if let rhs = object as? XBool {
            return self.value == rhs.value
        } else {
            return false
        }
    }
    public override var hash: Int {
        return self.value ? Int.max : 0
    }
    
    public static func bool(_ value: Bool) -> XBool {
        return value ? trueValue : falseValue
    }
    
    public static let trueValue: XBool = XBool(true)
    public static let falseValue: XBool = XBool(false)
}

public final class XTimeval : NSObject, NSCopying {
    public let value: Timeval
    
    private init(_ value: Timeval) {
        self.value = value
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override func isEqual(to object: Any?) -> Bool {
        if let rhs = object as? XTimeval {
            return self.value == rhs.value
        } else {
            return false
        }
    }
    public override var hash: Int {
        return self.value.hashValue
    }
    
    public static func timeval(_ value: Timeval) -> XTimeval {
        return XTimeval(value)
    }
}
public final class XMessage : NSObject, NSCopying {
    public let value: Message
    
    public init(_ value: Message) {
        self.value = value
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override func isEqual(to object: Any?) -> Bool {
        if let rhs = object as? XMessage {
            return self.value == rhs.value
        } else {
            return false
        }
    }
    public override var hash: Int {
        return self.value.hashValue
    }
}

public final class XOrderedMap : NSObject, NSCopying {
    public let value: OrderedMap<XCValue, XCValue>
    
    public init(_ value: OrderedMap<XCValue, XCValue>) {
        self.value = value
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override func isEqual(to object: Any?) -> Bool {
        if let rhs = object as? XOrderedMap {
            return self.value == rhs.value
        } else {
            return false
        }
    }
    public override var hash: Int {
        return self.value.hashValue
    }
}
public final class XOrderedSet : NSObject, NSCopying {
    public let value: OrderedSet<XCValue>
    
    public init(_ value: OrderedSet<XCValue>) {
        self.value = value
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override func isEqual(to object: Any?) -> Bool {
        if let rhs = object as? XOrderedSet {
            return self.value == rhs.value
        } else {
            return false
        }
    }
    public override var hash: Int {
        return self.value.hashValue
    }
}







public class XCValueObject : NSObject, NSCopying {
    public let value: XCValue
    
    public init(_ value: XCValue) {
        self.value = value
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public override func isEqual(to object: Any?) -> Bool {
        if let rhs = object as? XCValueObject {
            return self.value == rhs.value
        } else {
            return false
        }
    }
    public override var hash: Int {
        return self.value.hashValue
    }

}
