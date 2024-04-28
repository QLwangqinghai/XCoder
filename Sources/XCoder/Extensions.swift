
import Foundation

extension NSNumber {
    public var isBoolType: Bool {
        let n = self as CFNumber
        return CFGetTypeID(n) == CFBooleanGetTypeID()
    }
    
    public static func number(xvalue: XCNumberValue_s) -> NSNumber? {
        switch xvalue.type {
        case Int(XCNumberTypeSInt.rawValue):
            return xvalue.value.s as NSNumber
        case Int(XCNumberTypeUInt.rawValue):
            return xvalue.value.u as NSNumber
        case Int(XCNumberTypeFloat64.rawValue):
            return xvalue.value.f as NSNumber
        default:
            return nil
        }
    }
}

//XSerialization
