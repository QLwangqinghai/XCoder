
import Foundation
import XCoder

public struct TestObject {
    public static let stringNumberElements: [(NSString, NSNumber)] = (1 ... 1000).map { index in
        var n = JSON.randomNumber()
        while n.doubleValue.isNaN {
            n = JSON.randomNumber()
        }
        return (JSON.randomString(), n)
    }
    
    public static let timeArray: [Timeval] = (1 ... 100000).map { index in
        if index == 0 {
            return Timeval(value: Int64.min)
        } else if index == 1 {
            return Timeval(value: Int64.max)
        } else {
            return Timeval(value: Int64.random(in: Int64.min ..< Int64.max))
        }
    }
    public static let uint63Array: [UInt64] = (1 ... 100000).map { index in
        if index == 0 {
            return 0
        } else if index == 1 {
            return UInt64.max / 2
        } else {
            return UInt64.random(in: 0 ..< UInt64.max / 2)
        }
    }
    public static let uint64Array: [UInt64] = (1 ... 100000).map { index in
        if index == 0 {
            return 0
        } else if index == 1 {
            return UInt64.max
        } else {
            return UInt64.random(in: 0 ..< UInt64.max)
        }
    }
    
}

public class XCTestObject {
    public let jsonObject: NSObject
    public let xobject: XCValue

    public init(_ value: XCValue) {
        self.jsonObject = value.jsonValue()
        self.xobject = value
    }
}

public struct Nanosecond : CustomStringConvertible {
    public var value: Int64
    
    public init(value: Int64) {
        self.value = value
    }
    
    public var description: String {
        return Nanosecond.formatter.string(from: self.value as NSNumber) ?? ""
    }
    
    public static let formatter: NumberFormatter = {
        var formater = NumberFormatter()
        formater.usesGroupingSeparator = true
        formater.groupingSize = 3
        formater.groupingSeparator = "_"
        formater.maximumFractionDigits = 7
        return formater
    } ()

    public static func += (lhs: inout Nanosecond, rhs: Nanosecond) {
        lhs = Nanosecond(value: lhs.value + rhs.value)
    }

    public static func -= (lhs: inout Nanosecond, rhs: Nanosecond) {
        lhs = Nanosecond(value: lhs.value - rhs.value)
    }

    public static func *= (lhs: inout Nanosecond, rhs: Nanosecond) {
        lhs = Nanosecond(value: lhs.value * rhs.value)
    }

    public static func /= (lhs: inout Nanosecond, rhs: Nanosecond) {
        lhs = Nanosecond(value: lhs.value / rhs.value)
    }

    public static func + (lhs: Nanosecond, rhs: Nanosecond) -> Nanosecond {
        return Nanosecond(value: lhs.value + rhs.value)
    }

    public static func - (lhs: Nanosecond, rhs: Nanosecond) -> Nanosecond {
        return Nanosecond(value: lhs.value - rhs.value)
    }

    public static func * (lhs: Nanosecond, rhs: Nanosecond) -> Nanosecond {
        return Nanosecond(value: lhs.value * rhs.value)
    }

    public static func / (lhs: Nanosecond, rhs: Nanosecond) -> Nanosecond {
        return Nanosecond(value: lhs.value / rhs.value)
    }
    
    
}


var map0: [AnyHashable : AnyHashable] = [:]
var map1: [AnyHashable : AnyHashable] = [:]

//map0[true] = "true"
//map1[1] = "true"

let a: Int8 = 1

map0[true as NSNumber] = "true"
map1[a as NSNumber] = "true"

let aa = a as NSNumber
let bb = NSNumber(booleanLiteral: true)

print("aa \(aa.isEqual(to: bb)) bb")

if map0.keys == map1.keys {
    print("keys equal")
} else {
    print("keys not equal")
}

if map0.map({ (k, v) in
    return v
}) == map1.map({ (k, v) in
    return v
}) {
    print("values equal")
} else {
    print("values not equal")
}

if map0 == map1 {
    print("equal")
} else {
    print("not equal")
}

public struct JSON {
    public let object: [String : Any?]
    public let xobject: XCValue

    public init(xobject: XCValue) {
        self.object = xobject.jsonValue() as! [String : Any?]
        self.xobject = xobject
    }
    
    public static func random(deep: Int) -> XCValue {
        if deep > 30 {
            return randomSingleValue()
        }
        // (3/2)e
        let rint = Int.random(in: 1 ... (30 + 30 * deep))
        switch rint {
        case 2:
            let count = Int.random(in: 0 ... 100)
            var array: [XCValue] = []
            array.reserveCapacity(count)
            for _ in 0 ..< count {
                array.append(random(deep: deep + 1))
            }
            return .array(array)
        case 1:
            return randomMap(deep: deep)
        default:
            return randomSingleValue()
        }
    }
    public static func randomMap(deep: Int) -> XCValue {
        let count = Int.random(in: 0 ... 100)
        var set: Set<XCValue> = []
        var array: [(XCValue, XCValue)] = []
        array.reserveCapacity(count)
        for _ in 0 ..< count {
            let key = XCValue.string(randomKey())
            if !set.contains(key) {
                set.insert(key)
                array.append((key, random(deep: deep + 1)))
            }
        }
        return .map(OrderedMap(uniqueKeysWithValues: array))
    }
    
    public static func random() -> JSON {
        let x = randomMap(deep: 0)
        return JSON(xobject: x)
    }
    
    public static func randomKey() -> NSString {
        let len = Int.random(in: 1 ... 32)
        let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
        arc4random_buf(p, len)
        let data = Data(bytes: p, count: len)
        let string = data.base64EncodedString().replacingOccurrences(of: "=", with: "")
        p.deallocate()
        return string as NSString
    }
    
    public static func randomString() -> NSString {
        let len = XCValue.randomLength(1000)
        var array: [UInt8] = []
        let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
        arc4random_buf(p, len)
        array.reserveCapacity(len * 2)
        let u8p = p.bindMemory(to: UInt8.self, capacity: len)
        for i in 0 ..< len {
            let u = u8p.advanced(by: i).pointee
            if u == 0 {
                array.append(0x2E)
            } else if (u >= 0x80) {
                array.append((u >> 6) | 0xC0)
                array.append((u & 0x3F) | 0x80)
            } else {
                array.append(u)
            }
        }
        
        let data = Data(array)
        let string = (String(data: data, encoding: .utf8) as? NSString) ?? randomKey()
        p.deallocate()
        return string
    }
    
    public static func randomNumber() -> NSNumber {
        return XCValue.randomNumber()
    }
    
    public static func randomSingleValue() -> XCValue {
        let type = Int.random(in: 0 ... 15)
        switch type {
        case 0:
            return .nil
        case 1:
            return .bool(Bool.random())
        default:
            if type % 2 == 0 {
                return .number(randomNumber())
            } else {
                return .string(randomString())
            }
        }
    }
}

extension XCValue {
    
    public func jsonValue() -> NSObject {
        switch self {
        case .nil:
            return NSNull()
        case .bool(let v):
            return NSNumber(booleanLiteral: v)
        case .string(let v):
            return v
        case .data(let v):
            return v
        case .array(let v):
            return v.map { item in
                return item.jsonValue()
            } as NSArray
        case .map(let v):
            let map: NSMutableDictionary = NSMutableDictionary()
            v.forEach { k, v in
                map.setObject(v.jsonValue(), forKey: k.jsonValue() as! NSCopying)
            }
            return map
        case .set(let v):
            var array: [Any?] = []
            v.forEach { k in
                array.append(k.jsonValue())
            }
            return array as NSArray
        case .number(let v):
            return v
        case .timeval(let v):
            return v.value as NSNumber
        case .message(let v):
            let map: NSMutableDictionary = NSMutableDictionary()
            v.collection.forEach { (k, v) in
                map.setObject(v.jsonValue(), forKey: k as NSNumber)
            }
            return map
        }
    }
    
    public static func random(deep: Int) -> XCValue {
        if deep > 30 {
            return randomSingleValue()
        }
        // (3/2)e
        let rint = Int.random(in: 0 ... (100 + 100 * deep))
        switch rint {
        case 0:
            let count = randomLength(300)
            var array: [XCValue] = []
            array.reserveCapacity(count)
            for _ in 0 ..< count {
                array.append(random(deep: deep + 1))
            }
            return .array(array)
        case 1:
            let count = randomLength(300)
            var set: Set<XCValue> = []
            var array: [(XCValue, XCValue)] = []
            array.reserveCapacity(count)
            for _ in 0 ..< count {
                let key = random(deep: deep + 1)
                if !set.contains(key) {
                    set.insert(key)
                    array.append((key, random(deep: deep + 1)))
                }
            }
            return .map(OrderedMap(uniqueKeysWithValues: array))
        case 2:
            let count = randomLength(300)
            var set: Set<XCValue> = []
            var array: [XCValue] = []
            array.reserveCapacity(count)
            for _ in 0 ..< count {
                let key = random(deep: deep + 1)
                if !set.contains(key) {
                    set.insert(key)
                    array.append(key)
                }
            }
            return .set(OrderedSet(uniqueKeys: array))
        case 3:
            let count = randomLength(300)
            var map: [Int64 : XCValue] = [:]
            for _ in 0 ..< count {
                map[Int64.random(in: 1 ... Int64.max)] = random(deep: deep + 1)
            }
            let message = Message(type: Int64.random(in: 0 ... Int64.max), collection: map)
            return .message(message)
        default:
            return randomSingleValue()
        }
    }
    
    public static func random() -> XCValue {
        return random(deep: 0)
    }
    
    public static func randomLength(_ max: Int) -> Int {
        if max < 64 {
            return Int.random(in: 0 ... max)
        } else if max < 4096 {
            let n = sqrt(Double(max))
            let up = Int(n.rounded(.up))
            return up * up
        } else {
            let n = sqrt(sqrt(Double(max)))
            let up0 = Int(n.rounded(.down))
            let up1 = up0 + 1
            let qlen0 = Int.random(in: 1 ... up0)
            let qlen1 = Int.random(in: 1 ... up1)
            return qlen0 * qlen0 * qlen1 * qlen1
        }
    }
    
    public static func randomNumber() -> NSNumber {
        let i = Int.random(in: 0 ... Int.max) % 7
        switch i {
        case 0:
            let n: Int64 = Int64.random(in: Int64.min ... Int64.max)
            return n as NSNumber
        case 1:
            let n: UInt64 = UInt64.random(in: UInt64.min ... UInt64.max)
            return n as NSNumber
        case 2:
            let n: UInt32 = UInt32.random(in: UInt32.min ... UInt32.max)
            return n as NSNumber
        case 3:
            let n: Int32 = Int32.random(in: Int32.min ... Int32.max)
            return n as NSNumber
        case 4:
            let n: UInt16 = UInt16.random(in: UInt16.min ... UInt16.max)
            return n as NSNumber
        case 5:
            let n: Int16 = Int16.random(in: Int16.min ... Int16.max)
            return n as NSNumber
        default:
            let bitPattern = UInt64.random(in: UInt64.min ... UInt64.max)
            let n = Double(bitPattern: bitPattern) as NSNumber
            return n as NSNumber
        }
    }

    
    public static func randomSingleValue() -> XCValue {
        let type = Int.random(in: 0 ... 49)
        switch type {
        case 0:
            var string = ""
            let len = randomLength(70000)
            let p = UnsafeMutableRawPointer.allocate(byteCount: len * 2, alignment: 8)
            arc4random_buf(p, len)
            let uint16p = p.bindMemory(to: UInt16.self, capacity: len)
            for i in 0 ..< len {
                let u = uint16p.advanced(by: i).pointee
                string += String(UTF32Char(u == 0 ? 1 : u))
            }
            p.deallocate()
            return .string(string as NSString)
        case 1:
            let len = randomLength(4000000)
            let p = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: 8)
            arc4random_buf(p, len)
            let data = Data(bytes: p, count: len)
            p.deallocate()
            return .data(data as NSData)
        default:
            switch (type - 2) % 6 {
            case 0:
                return .nil
            case 1:
                return .bool(Bool.random())
            case 2:
                return .timeval(Timeval.random())
            default:
                let numbers: [Double] = [Double.zero, Double.nan, Double.infinity, -1 * Double.infinity]
                let i = Int.random(in: 0 ... 1023)
                if i < 4 {
                    return .number(numbers[i] as NSNumber)
                } else {
                    return .number(randomNumber())
                }
            }
        }
    }
    
}


let string: NSString = "asdfryejfkj"
let string2: NSString = "()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj()2asdfryejfkj--asdfryejfkj&*asdfryejfkj--asdfryejfkj"


func testBool() {
    try! {
        let data = try XSerialization.encode(value: .nil)
        assert(data.count == 1 && data[0] == 0, "error")
    } ()

    try! {
        let data = try XSerialization.encode(value: .bool(true))
        let b = try XSerialization.decode(data: data)!
        assert(try! b.boolValue() == true)
    } ()

    try! {
        let data = try XSerialization.encode(value: .bool(false))
        let b = try XSerialization.decode(data: data)!
        assert(try! b.boolValue() == false)
    } ()
}

func testString() {
    try! {
        let data = try XSerialization.encode(value: .string(string))
        let b = try XSerialization.decode(data: data)!
        assert(try! b.stringValue() == string)
    } ()
    try! {
        let data = try XSerialization.encode(value: .string(string2))
        let b = try XSerialization.decode(data: data)!
        assert(try! b.stringValue() == string2)
    } ()
    
    try! {
        var string = ""
        for i in 1 ... 10000 {
            string = string2 as String
        }
        let data = try XSerialization.encode(value: .data(string.data(using: .utf8)! as NSData))
        let b = try XSerialization.decode(data: data)!
        assert(try! b.dataValue() as Data == string.data(using: .utf8)!)
    } ()
}

func testData() {
    try! {
        let data = try XSerialization.encode(value: .timeval(Timeval(value: Int64.max)))
        let b = try XSerialization.decode(data: data)!
        assert(try! b.timevalValue().value == Int64.max)
    } ()
    try! {
        let data = try XSerialization.encode(value: .timeval(Timeval(value: Int64.min)))
        let b = try XSerialization.decode(data: data)!
        assert(try! b.timevalValue().value == Int64.min)
    } ()
}

func testNumber() {
    
    try! {
        let n = Double.nan as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()

    try! {
        let n = Double.infinity as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()
    try! {
        let n = (-1.0 * Double.infinity) as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()
    try! {
        let n = Double.zero as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()
    try! {
        let v: UInt64 = 479782221394380
        let n = Double.init(bitPattern: v) as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()
    for _ in 0 ..< 10000 {
        // 非规约数
        try! {
            let v = UInt64.random(in: 0 ..< 1 << 52)
            let n = Double.init(bitPattern: v) as NSNumber
            let data = try! XSerialization.encode(value: .number(n))
            let b = try! XSerialization.decode(data: data)!
            assert(try! b.numberValue() == n)
        } ()
    }

    try! {
        let n = Int64.max as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()
    try! {
        let n = Int64.min as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()

    try! {
        let n = UInt64.max as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()
    try! {
        let n = UInt64.min as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()

    try! {
        let n = Int64.random(in: Int64.min ... Int64.max) as NSNumber
        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()

    try! {
        // 13128835290283576832 0xB632FE230FF70E00
        // 15164535251138657408 0xD27340773C023C80
        let v: Int64 = -3282208822570894208
        let n = v as NSNumber

        let data = try! XSerialization.encode(value: .number(n))
        let b = try! XSerialization.decode(data: data)!
        assert(try! b.numberValue() == n)
    } ()


    try! {
        let bitPattern: UInt64 = 13833650284833841868
        let n = Double(bitPattern: bitPattern) as NSNumber
        do {
            let data = try! XSerialization.encode(value: .number(n))
            let b = try XSerialization.decode(data: data)!
            assert(try! b.numberValue() == n)
        } catch let error {
            print("\(bitPattern)  :  \(n)  \nerror:\(error)")
            abort()
        }
    } ()

    for _ in 0 ..< 10000 {
        try! {
            let bitPattern = UInt64.random(in: UInt64.min ... UInt64.max)
            let n = Double(bitPattern: bitPattern) as NSNumber
            do {
                let data = try! XSerialization.encode(value: .number(n))
                let b = try XSerialization.decode(data: data)!
                assert(try! b.numberValue() == n)
            } catch let error {
                print("\(bitPattern)  :  \(n)  \nerror:\(error)")
                abort()
            }
        } ()
    }
}

func testTimeval() {
    let values = TestObject.timeArray.map { timeval in
        return XCTestObject(.timeval(timeval))
    }
    
    testCoder(tag: "Timeval", objects: values, times: 10)
}

func testSingle() {
    testBool()
    testData()
    testString()
    testNumber()
    testTimeval()
}

//try! {
//    let data = try XSerialization.encode(value: .data(string.data(using: .utf8)!))
//    let b = try XSerialization.decode(data: data)!
//    assert(try! b.dataValue() == string.data(using: .utf8)!)
//} ()
//try! {
//    let data = try XSerialization.encode(value: .data(string2.data(using: .utf8)!))
//    let b = try XSerialization.decode(data: data)!
//    assert(try! b.dataValue() == string2.data(using: .utf8)!)
//} ()



//▿ 5 : XCValue
//  - number : -8535150335806580789
//▿ 6 : XCValue
//  ▿ timeval : Timeval
//    - value : 1034584475061637028
//▿ 7 : XCValue
//  - number : 5280776537546213781
//▿ 8 : XCValue
//  - number : -6901312967598468725




//        try! {
//            let v: UInt64 = 1 << 51
//            let d = Double(bitPattern: v)
//            let d80 = Float80(d)
//
//
//            let numberContent = _XCEncodeNumberFloat64(d)
//            assert(d80.exponent == numberContent.exponent)
//        } ()
//
//
//        try! {
//            let v: UInt64 = 1
//            let d = Double(bitPattern: v)
//            let d80 = Float80(d)
//
//            let numberContent = _XCEncodeNumberFloat64(d)
//            assert(d80.exponent == numberContent.exponent)
//        } ()

func randomSingleValueArray(count: Int) -> [XCValue] {
    var array: [XCValue] = []
    array.reserveCapacity(count)
    for _ in 0 ..< count {
        array.append(XCValue.randomSingleValue())
    }
    return array
}
func randomSingleValueMap(count: Int) -> XMap {
    var set: Set<XCValue> = []
    var array: [(XCValue, XCValue)] = []
    array.reserveCapacity(count)
    for _ in 0 ..< count {
        let key = XCValue.randomSingleValue()
        if !set.contains(key) {
            set.insert(key)
            array.append((key, XCValue.randomSingleValue()))
        }
    }
    return OrderedMap(uniqueKeysWithValues: array)
}

func randomSingleValueSet(count: Int) -> XSet {
    var set: Set<XCValue> = []
    var array: [XCValue] = []
    array.reserveCapacity(count)
    for _ in 0 ..< count {
        let key = XCValue.randomSingleValue()
        if !set.contains(key) {
            set.insert(key)
            array.append(key)
        }
    }
    return OrderedSet(uniqueKeys: array)
}

func randomSingleValueMessage(count: Int) -> Message {
    var map: [Int64 : XCValue] = [:]
    for _ in 0 ..< count {
        map[Int64.random(in: 1 ... Int64.max)] = XCValue.randomSingleValue()
    }
    return Message(type: Int64.random(in: 0 ... Int64.max), collection: map)
}

func testCollection() {
    autoreleasepool {
        let value: XCValue = .array([XCValue.bool(true), XCValue.bool(false), XCValue.bool(true), XCValue.number(-4935517242844051799), XCValue.number(7254530496614344569), XCValue.timeval(Timeval(value: -6575567707239634815))])
        
        let data = try! XSerialization.encode(value: value)
        let b = try! XSerialization.decode(data: data)!

        assert(b == value)

    }
    for _ in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XCValue = .array(randomSingleValueArray(count: count))
            let data = try! XSerialization.encode(value: value)
            
            let b = try! XSerialization.decode(data: data)!
            assert(b == value)
        }
    }

    for _ in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XCValue = .map(randomSingleValueMap(count: count))
            let data = try! XSerialization.encode(value: value)
            let b = try! XSerialization.decode(data: data)!
            assert(b == value)
        }
    }
    for _ in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XCValue = .set(randomSingleValueSet(count: count))
            let data = try! XSerialization.encode(value: value)
            let b = try! XSerialization.decode(data: data)!
            assert(b == value)
        }
    }
    for i in 0 ..< 10 {
        autoreleasepool {
            let count: Int = Int.random(in: 0 ... 333)
            let value: XCValue = .message(randomSingleValueMessage(count: count))
            let data = try! XSerialization.encode(value: value)
            let b = try! XSerialization.decode(data: data)!
            if b != value {
                
                abort()
            }
        }
    }
}




public class XCBuffer {
    public var count: Int = 0
    private var capacity: Int
    private var _bytes: UnsafeMutableRawPointer
    
    public var bytes: UnsafeMutablePointer<UInt8> {
        return self._bytes.bindMemory(to: UInt8.self, capacity: self.capacity)
    }
    
    public init(minimumCapacity: Int) {
        let value = XCBuffer.capacityAlign(minimumCapacity)
        self.capacity = value
        self._bytes = realloc(nil, value)
    }
    
    public func reserveCapacity(_ minimumCapacity: Int) {
        guard minimumCapacity >= self.capacity else {
            return
        }
        let value = XCBuffer.capacityAlign(minimumCapacity)
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
}

func testVarint(buffer: XCBuffer, encode: XCVarintEncode_f, decode: XCVarintDecode_f) -> Nanosecond {
    let ptr = buffer.bytes.advanced(by: 1)
    let time0: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    TestObject.uint63Array.forEach { v in
        var location = 0
        let e = encode(ptr, 1024, &location, v)
        
        location = 0
        var result: UInt64 = 0
        let e2 = decode(ptr, 1024, &location, &result)
        
        if e != e2 {
            abort()
        }
    }
    let time1: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    
    return Nanosecond(value: Int64((time1 - time0) * 1000000000))
}

func testVarint() {
//    TestObject.uint63Array
//    TestObject.uint64Array
//
//
//    let buffer = XCBuffer(minimumCapacity: 1024 * 10 * 10)
//
//    usleep(1000000)
//
//    TestObject.uint63Array.forEach { _ in
//
//    }
//
//    let int64time = testVarint(buffer: buffer, encode: __XCEncodeUInt64Varint, decode: __XCDecodeUInt64Varint)
//
//    usleep(1000000)
//
//
//    TestObject.uint63Array.forEach { _ in
//
//    }
//    let int63time = testVarint(buffer: buffer, encode: __XCEncodeUInt63Varint, decode: __XCDecodeUInt63Varint)
//
////    let int63time = testVarint(buffer: buffer, encode: __XCEncodeUInt64Varint2, decode: __XCDecodeUInt64Varint)
//
//    print("testVarint: int64time:\(int64time) int63time:\(int63time) fast:\(int64time - int63time)")
    
}

public struct CodeInfo {
    public var encode: CFAbsoluteTime
    public var decode: CFAbsoluteTime
    public var data: Int
    
    public var code: CFAbsoluteTime {
        return encode + decode
    }
    public var codeString: String {
        return CodeInfo.formatter.string(from: self.code as NSNumber) ?? ""
    }
    public var encodeString: String {
        return CodeInfo.formatter.string(from: self.encode as NSNumber) ?? ""
    }
    public var decodeString: String {
        return CodeInfo.formatter.string(from: self.decode as NSNumber) ?? ""
    }
    public var dataString: String {
        var v = self.data
        var string = ""
        if v >= 1024 * 1024 {
            let mb = 1024 * 1024
            string += String(format: "%ld_", v / mb)
            v = v % mb
            string += String(format: "%04ld_", v / 1024)
            v = v % 1024
            string += String(format: "%04ld", v)
        } else if v >= 1024 {
            string += String(format: "%04ld_", v / 1024)
            v = v % 1024
            string += String(format: "%04ld", v)
        } else {
            string += String(format: "%04ld", v)
        }
        return string
    }

    public init(encode: CFAbsoluteTime, decode: CFAbsoluteTime, data: Int) {
        self.encode = encode
        self.decode = decode
        self.data = data
    }
    
    public static let formatter: NumberFormatter = {
        var formater = NumberFormatter()
        formater.usesGroupingSeparator = true
        formater.groupingSize = 6
        formater.groupingSeparator = "_"
        formater.maximumFractionDigits = 7
        return formater
    } ()
    
    public static func + (lhs: CodeInfo, rhs: CodeInfo) -> CodeInfo {
        return CodeInfo(encode: lhs.encode + rhs.encode, decode: lhs.decode + rhs.decode, data: lhs.data + rhs.data)
    }

    public static func - (lhs: CodeInfo, rhs: CodeInfo) -> CodeInfo {
        return CodeInfo(encode: lhs.encode - rhs.encode, decode: lhs.decode - rhs.decode, data: lhs.data - rhs.data)
    }
    
}
public struct Profile : CustomStringConvertible {
    public var tag: String
    public var x: CodeInfo
    public var json: CodeInfo

    public init(tag: String, x: CodeInfo, json: CodeInfo) {
        self.tag = tag
        self.x = x
        self.json = json
    }
    

    public var description: String {
        let delta = self.json - self.x
        
        func scale(_ s: Double) -> String {
            return String(format: "%.03lf", s)
        }
        
        var result = ""
        result += "\(tag) x: total: \(x.codeString), encode: \(x.encodeString), decode: \(x.decodeString), data: \(x.dataString)\n"
        result += "\(tag) json: total: \(json.codeString), encode: \(json.encodeString), decode: \(json.decodeString), data: \(json.dataString)\n"
        result += "\(tag) delta: total: \(delta.codeString), encode: \(delta.encodeString), decode: \(delta.decodeString), data: \(delta.dataString)\n"
        result += "\(tag) codefast: \(scale(delta.code / x.code)), encode fast: \(scale(delta.encode / x.encode)), decode fast: \(scale(delta.decode / x.decode)), data less: \(scale(Double(delta.data) / Double(x.data))))\n"
        return result
    }
    
}

public func testCoder(tag: String, objects: [XCTestObject], times: Int) {
    var time0: CFAbsoluteTime = 0
    var time0a: CFAbsoluteTime = 0
    var time0b: CFAbsoluteTime = 0
    var dataSum0: Int = 0

    let range = 0 ..< times

    let values = objects.map { value in
        return value.xobject
    }
    
    range.forEach { i in
        for value in values {
            autoreleasepool {
                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let data = try! XSerialization.encode(value: value)
                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let decoded = try! XSerialization.decode(data: data)!
                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

                time0 += end - start
                time0a += mtime - start
                time0b += end - mtime
                dataSum0 += data.count
                
                assert(value == decoded)
            }
        }
    }

    usleep(1000000)

    var time1: CFAbsoluteTime = 0
    var time1a: CFAbsoluteTime = 0
    var time1b: CFAbsoluteTime = 0

    var dataSum1: Int = 0
    
    let jsons = objects.map { value in
        return value.jsonObject
    }
    range.forEach { i in
        for json in jsons {
            autoreleasepool {
                let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let data = JSONCoder.encode(json)
                let mtime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                let object = JSONCoder.decode(data)
                let end: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
                
                time1 += end - start
                time1a += mtime - start
                time1b += end - mtime
                dataSum1 += data.count

                if i == 1 {
                    //  && index == 1
//                    if let str = String(data: data, encoding: .utf8) {
//                        print("JSON: \(str)")
//                    }
                }

                let results = NSMutableArray()
                if !compareJsonObject(lhs: json, rhs: object, results: results) {
                    abort()
                }
                if results.count > 0 {
//                    print("")
//                    print(results)
//                    print("")
                }
            }
        }
    }
    
    let x = CodeInfo(encode: time0a, decode: time0b, data: dataSum0)
    let json = CodeInfo(encode: time1a, decode: time1b, data: dataSum1)

    let profile = Profile(tag: tag, x: x, json: json)
    print(profile)
    
}


public func testNumbers() {
    let tag = "Number"
    let values: [XCTestObject] = TestObject.stringNumberElements.map { (_, n) in
        return XCTestObject(.number(n))
    }
    testCoder(tag: tag, objects: values, times: 100)
}

public func testStrings() {
    let tag = "String"
    let values: [XCTestObject] = TestObject.stringNumberElements.map { (s, _) in
        return XCTestObject(.string(s))
    }
    testCoder(tag: tag, objects: values, times: 100)
}

func testStringNumberArray() {
    let tag = "[String,Number]"
    usleep(1000000)

    let values: [XCTestObject] = TestObject.stringNumberElements.map { (s, n) in
        return XCTestObject(.array([.string(s), .number(n)]))
    }
    
    testCoder(tag: tag, objects: values, times: 100)
}
public func testStringNumberMap() {
    usleep(1000000)

    let tag = "{string:Number}"

    //let tag = "JSON.random"

    let values: [XCTestObject] = TestObject.stringNumberElements.map { (s, n) in
        var map: XMap = XMap()
        map[.string(s)] = .number(n)
        return XCTestObject(.map(map))
    }

    testCoder(tag: tag, objects: values, times: 100)
}

public func testRandomedJson() {
    let tag = "JSON.random"

    let values: [XCTestObject] = (1 ... 100).map { index -> JSON in
        var result = JSON.random()
        while !JSONSerialization.isValidJSONObject(result.object) {
            result = JSON.random()
        }
        return result
    }.map { value in
        return XCTestObject(value.xobject)
    }
    usleep(1000000)
    
    testCoder(tag: tag, objects: values, times: 100)
}

func compareDictionary(lhs: NSDictionary, rhs: NSDictionary, results: NSMutableArray) -> Bool {
    guard lhs.count == rhs.count else {
        results.add(NSString(format: "%@ | %@", lhs, rhs))
        return false
    }
    var result = true
    lhs.allKeys.forEach { k in
        let lv = lhs.object(forKey: k)! as! NSObject
        let rv = rhs.object(forKey: k) as! NSObject
        let r = compareJsonObject(lhs: lv, rhs: rv, results: results)
        if !r {
            result = false
        }
    }
    return result
}

func compareArray(lhs: NSArray, rhs: NSArray, results: NSMutableArray) -> Bool {
    guard lhs.count == rhs.count else {
        results.add(NSString(format: "%@ | %@", lhs, rhs))
        return false
    }
    var result = true
    lhs.enumerated().forEach { (index, item) in
        let r = compareJsonObject(lhs: item as! NSObject, rhs: rhs.object(at: index) as! NSObject, results: results)
        if !r {
            result = false
        }
    }
    return result
}

func compareJsonObject(lhs l: Any, rhs r: Any, results: NSMutableArray) -> Bool {
    guard let lhs = l as? NSObject, let rhs = r as? NSObject else {
        results.add("\(l) | (r)" as NSString)
        return false
    }
    
    if !lhs.isEqual(to: rhs) {
        if lhs is NSNumber {
            if let lvd = lhs as? Double, let rvd = rhs as? Double {
                let d = lvd - rvd
                let string = NSString(format: "%.012lf", d)
                results.add(NSString(format: "%@ | %@  [%@]", lhs, rhs, string))
                if d > 0.00000000001 || d < -0.00000000001 {
                    return false
                } else {
                    return true
                }
            }
        } else if lhs is NSString {
            results.add(NSString(format: "%@ | %@", lhs, rhs))
            return false
        } else if let lv = lhs as? NSArray {
            return compareArray(lhs: lv, rhs: rhs as! NSArray, results: results)
        } else if let lv = lhs as? NSDictionary {
            return compareDictionary(lhs: lv, rhs: rhs as! NSDictionary, results: results)
        } else {
            results.add(NSString(format: "%@ | %@", lhs, rhs))
            return false
        }
    }
    return true
}

//for i in 1 ..< 1000 {
//    testVarint()
//}
testSingle()
testNumbers()
testStrings()
testStringNumberArray()
testStringNumberMap()

testCollection()
testRandomedJson()
