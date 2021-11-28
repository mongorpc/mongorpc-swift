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
