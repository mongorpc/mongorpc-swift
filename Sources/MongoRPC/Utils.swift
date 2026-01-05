import Foundation
import SwiftProtobuf

// MARK: - Value Conversion

extension Mongorpc_V1_Value {
    static func from(_ value: Any?) -> Mongorpc_V1_Value {
        var v = Mongorpc_V1_Value()
        
        guard let value = value else {
            v.nullValue = .nullValue
            return v
        }
        
        if let b = value as? Bool {
            v.booleanValue = b
        } else if let i = value as? Int {
            v.int64Value = Int64(i)
        } else if let i = value as? Int64 {
            v.int64Value = i
        } else if let d = value as? Double {
            v.doubleValue = d
        } else if let s = value as? String {
            v.stringValue = s
        } else if let date = value as? Date {
            // TODO: Timestamp
            v.stringValue = ISO8601DateFormatter().string(from: date)
        } else if let objectId = value as? Mongorpc_V1_ObjectId {
            v.objectIDValue = objectId
        } else if let arr = value as? [Any] {
            var arrayValue = Mongorpc_V1_ArrayValue()
            arrayValue.values = arr.map { Mongorpc_V1_Value.from($0) }
            v.arrayValue = arrayValue
        } else if let dict = value as? [String: Any] {
            var mapValue = Mongorpc_V1_MapValue()
            mapValue.fields = dict.mapValues { Mongorpc_V1_Value.from($0) }
            v.mapValue = mapValue
        } else {
             // Fallback to string representation
            v.stringValue = String(describing: value)
        }
        return v
    }
    
    func toAny() -> Any? {
        switch valueType {
        case .nullValue: return nil
        case .booleanValue(let b): return b
        case .int64Value(let i): return Int(i) // Or keep as Int64?
        case .doubleValue(let d): return d
        case .stringValue(let s): return s
        case .arrayValue(let a): return a.values.map { $0.toAny() }
        case .mapValue(let m): return m.fields.mapValues { $0.toAny() }
        case .objectIDValue(let o): return o.hex
        default: return nil
        }
    }
}

// MARK: - Document Conversion

extension Mongorpc_V1_Document {
    static func from(_ dict: [String: Any]) -> Mongorpc_V1_Document {
        var doc = Mongorpc_V1_Document()
        if let id = dict["_id"] as? String {
            doc.id = Mongorpc_V1_ObjectId.with { $0.hex = id }
        }
        
        for (k, v) in dict {
            if k != "_id" {
                doc.fields[k] = Mongorpc_V1_Value.from(v)
            }
        }
        return doc
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        if hasID {
            dict["_id"] = id.hex
        }
        for (k, v) in fields {
            dict[k] = v.toAny()
        }
        return dict
    }
}

// MARK: - Filter Conversion

extension Mongorpc_V1_Filter {
    static func from(_ dict: [String: Any]) -> Mongorpc_V1_Filter {
        var filter = Mongorpc_V1_Filter()
        var mapValue = Mongorpc_V1_MapValue()
        mapValue.fields = dict.mapValues { Mongorpc_V1_Value.from($0) }
        filter.raw = mapValue
        return filter
    }
}

// MARK: - UpdateSpec Conversion

extension Mongorpc_V1_UpdateSpec {
    static func from(_ dict: [String: Any]) -> Mongorpc_V1_UpdateSpec {
        var spec = Mongorpc_V1_UpdateSpec()
        var ops = Mongorpc_V1_UpdateOperators()
        
        if let setDict = dict["$set"] as? [String: Any] {
            ops.set = setDict.mapValues { Mongorpc_V1_Value.from($0) }
        }
        
        if let incDict = dict["$inc"] as? [String: Any] {
            ops.inc = incDict.mapValues { Mongorpc_V1_Value.from($0) }
        }
        
        if let unsetDict = dict["$unset"] as? [String: Any] {
            ops.unset = Array(unsetDict.keys)
        }
        
        spec.operators = ops
        return spec
    }
}
