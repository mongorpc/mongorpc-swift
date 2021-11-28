import Foundation

func decode(value: Mongorpc_Value) -> Any? {
    guard let type = value.type else {
        return nil
    }
    switch type {
    case let .integer32Value(integer32):
        return integer32
    case let .integer64Value(integer64):
        return Int(integer64)
    case let .booleanValue(bool):
        return bool
    case let .stringValue(str):
        return str
    case let .doubleValue(double):
        return double
    case .nullValue:
        return nil
    case let .arrayValue(arr):
        return arr.values.map { decode(value: $0) }
    case let .mapValue(dict):
        var result: [String: Any] = [:]
        for (k, value) in dict.fields {
            result[k] = decode(value: value)
        }
        return result
    case let .objectIDValue(objectID):
        return ObjectID(id: objectID.id)
    case let .timestampValue(timestamp):
        return Date(timeIntervalSince1970: Double(timestamp.seconds) / 1000)
    }
}
