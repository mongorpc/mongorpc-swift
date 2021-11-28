import Foundation

func encode(value: Any?) -> Mongorpc_Value {
    var result = Mongorpc_Value()
    guard let value = value else {
        result.nullValue = Mongorpc_NullValue.nullValue
        return result
    }

    if let integer64Value: Int64 = value as? Int64 {
        result.integer64Value = integer64Value
    }

    if let integer: Int32 = value as? Int32 {
        result.integer32Value = integer
    }

    if let integer: Int = value as? Int {
        result.integer64Value = Int64(integer)
    }

    if let bool: Bool = value as? Bool {
        result.booleanValue = bool
    }

    if let double: Double = value as? Double {
        result.doubleValue = double
    }

    if let string: String = value as? String {
        result.stringValue = string
    }

    if let array: [Any] = value as? [Any] {
        var arrayValue = Mongorpc_ArrayValue()
        arrayValue.values = array.map { encode(value: $0) }
        result.arrayValue = arrayValue
    }

    if let dictionary: [String: Any] = value as? [String: Any] {
        var dictionaryValue = Mongorpc_MapValue()
        for (k, value) in dictionary {
            dictionaryValue.fields[k] = encode(value: value)
        }
        result.mapValue = dictionaryValue
    }

    if let date: Date = value as? Date {
        var dateValue = Mongorpc_Timestamp()
        dateValue.seconds = Int64(date.timeIntervalSince1970 * 1000)
        result.timestampValue = dateValue
    }

    if let objectID: ObjectID = value as? ObjectID {
        result.objectIDValue.id = objectID.id
    }

    return result
}
