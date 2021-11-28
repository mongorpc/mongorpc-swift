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


@testable import MongoRPC
import XCTest

final class MongoRPCTests: XCTestCase {

    
    func testNullValueEncoderDecoder() {
        XCTAssertNil(decode(value: encode(value: nil)))
    }
    
    func testIntegerValueEncoderDecoder() {
        XCTAssertEqual(decode(value: encode(value: 120396)) as! Int, 120396)
    }
    
    func testDoubleValueEncoderDecoder() {
        XCTAssertEqual(decode(value: encode(value: 12.0396)) as! Double, 12.0396)
    }
    
    func testBoolValueEncoderDecoder() {
        XCTAssertEqual(decode(value: encode(value: false)) as! Bool, false)
    }
    
    func testStringValueEncoderDecoder() {
        XCTAssertEqual(decode(value: encode(value: "Nisha")) as! String, "Nisha")
    }
    
    func testArrayValueEncoderDecoder() {
        XCTAssertEqual(decode(value: encode(value: [1,2,3])) as! [Int], [1,2,3])
    }
    
    func testDictValueEncoderDecoder() {
        let value : [String : String] = [
            "full_name": "mongorpc/mongorpc",
            "description": "MongoDB + gRPC = mongorpc",
                "url": "https://api.github.com/repos/mongorpc/mongorpc",
        ]
        XCTAssertEqual(decode(value: encode(value: value as Any)) as! [String : String], value)
    }
}
