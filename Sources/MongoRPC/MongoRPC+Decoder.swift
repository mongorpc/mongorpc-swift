// Copyright 2021 MongoRPC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
