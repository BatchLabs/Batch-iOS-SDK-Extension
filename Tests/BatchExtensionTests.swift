//
//  BatchExtensionTests.swift
//  BatchExtensionTests
//
//  Created by Arnaud Barisain-Monrose on 23/10/2019.
//  Copyright © 2019 Batch. All rights reserved.
//

import XCTest
@testable import BatchExtension

extension Data {
    
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

class BatchExtensionTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testURLExtraction() {
        let validURL = "https://batch.com/foo.png"
        let validType = "image/png"
        
        let validPayload: [AnyHashable: Any] = [
            "com.batch": ["at":["u":validURL, "t": validType]]
        ]
        
        let invalidURLPayload: [AnyHashable: Any] = [
            "com.batch": ["u":"foobar$", "t": "image/png"]
        ]
        
        let missingPayloads: [[AnyHashable: Any]] = [
            [:],
            ["foo":"bar"],
            ["com.batch":["foo":"bar"]],
            ["com.batch":["at":[:]]],
            ["com.batch":["at":["foo":"bar"]]],
            ["com.batch":["at":["u":"https://batch.com/favicon.ico"]]],
            ["com.batch":["at":["t":"image/jpeg"]]]
        ]
        
        let attachment = try! RichNotificationHelper().attachment(forPayload: validPayload)
        XCTAssertEqual(attachment.url,
                       URL(string: validURL)!)
        XCTAssertEqual(attachment.type, validType)
        
        XCTAssertThrowsError(try RichNotificationHelper().attachment(forPayload: invalidURLPayload))
        
        for payload in missingPayloads {
            XCTAssertThrowsError(try RichNotificationHelper().attachment(forPayload: payload))
        }
    }

    func testDisplayReceiptExtraction() {
        
        let invalidPayload: [AnyHashable: Any] = [:]
        let invalidReceipt = try? DisplayReceiptHelper().displayReceipt(fromPayload: invalidPayload)
        XCTAssertNil(invalidReceipt)
        
        let validPayload: [AnyHashable: Any] = [
            "com.batch": ["r":["m":1]]
        ]
        
        let receipt = try! DisplayReceiptHelper().displayReceipt(fromPayload: validPayload)
        XCTAssertFalse(receipt.replay)
        XCTAssertEqual(receipt.sendAttempt, 0)
        XCTAssertTrue(receipt.od == nil || receipt.od!.isEmpty)
        XCTAssertTrue(receipt.ed == nil || receipt.ed!.isEmpty)
        
        let validPayload2: [AnyHashable: Any] = [
            "com.batch": ["r":["m":2]]
        ]
        
        let receipt2 = try! DisplayReceiptHelper().displayReceipt(fromPayload: validPayload2)
        XCTAssertFalse(receipt2.replay)
        XCTAssertEqual(receipt2.sendAttempt, 0)
        XCTAssertTrue(receipt.od == nil || receipt.od!.isEmpty)
        XCTAssertTrue(receipt.ed == nil || receipt.ed!.isEmpty)
    }
    
    func testDisplayReceiptOpenDataExtraction() {
        
        let od: [AnyHashable: Any] = [
            "sef": "toto", "bool": true, "hip": "hop"
        ]
        
        let validPayload: [AnyHashable: Any] = [
            "com.batch": ["r":["m":1], "od": od]
        ]
        
        let receipt = try! DisplayReceiptHelper().displayReceipt(fromPayload: validPayload)
        XCTAssertFalse(receipt.replay)
        XCTAssertEqual(receipt.sendAttempt, 0)
        XCTAssert(NSDictionary(dictionary: od).isEqual(to: receipt.od!));
        XCTAssertTrue(receipt.ed == nil || receipt.ed!.isEmpty)
    }
    
    func testDisplayReceiptEventDataExtraction() {
        let validPayload: [AnyHashable: Any] = [
            "com.batch": ["r":["m":1], "i": "test-i", "ex": "test-ex", "va": "test-va"]
        ]
        
        let ed: [AnyHashable: Any] = [
            "i": "test-i", "ex": "test-ex", "va": "test-va"
        ]
        
        let receipt = try! DisplayReceiptHelper().displayReceipt(fromPayload: validPayload)
        XCTAssertFalse(receipt.replay)
        XCTAssertEqual(receipt.sendAttempt, 0)
        XCTAssertTrue(receipt.od == nil || receipt.od!.isEmpty)
        XCTAssert(NSDictionary(dictionary: ed).isEqual(to: receipt.ed!));
    }
    
    func testReceiptPackUnpack() throws {
        
        let nestedList = [
            false,
            "yolo",
            25.69745,
            654,
            nil
        ] as [Any?]
        
        let nestedOd = [
            "bool": false,
            "int": 654,
            "float": 64.285,
            "list": nestedList,
            "null": nil
        ] as [AnyHashable : Any?]
        
        let od = [
            "n": "je-suis-un-n",
            "t": "je-suis-un-c",
            "ak": "je-suis-un-ak",
            "di": "je-suis-un-di",
            "map": nestedOd,
            "list": nestedList,
            "bool_true": true,
            "bool_false": false
        ] as [AnyHashable : Any]
        
        let ed = [
            "i": "je-suis-un-i",
            "e": "je-suis-un-e",
            "v": "je-suis-un-v"
        ]
        
        let receipt = DisplayReceipt(timestamp: 123456, replay: false, sendAttempt: 19, od: od, ed: ed)
        XCTAssertNotNil(receipt)
        
        let packedData = try receipt.pack()
        XCTAssertNotNil(packedData);
        
        let unpackReceipt = try DisplayReceipt.unpack(from: packedData)
        XCTAssertNotNil(unpackReceipt);
        
        XCTAssertEqual(unpackReceipt.timestamp, 123456);
        XCTAssertEqual(unpackReceipt.replay, false);
        XCTAssertEqual(unpackReceipt.sendAttempt, 19);
        XCTAssert(NSDictionary(dictionary: od).isEqual(to: unpackReceipt.od!));
        XCTAssert(NSDictionary(dictionary: ed).isEqual(to: unpackReceipt.ed!));
    }
    
    func testReceiptPackEmptyMap() throws {
        let emptyDictionary = [AnyHashable: Any?]()
        let receipt = DisplayReceipt(timestamp: 65481651581, replay: true, sendAttempt: 6585, od: emptyDictionary, ed: emptyDictionary)
        XCTAssertNotNil(receipt)
        
        let packedData = try receipt.pack()
        XCTAssertNotNil(packedData);
        
        XCTAssertEqual("cf0000000f3f02b57dc3cd19b9c0c0", packedData.hexString());
    }
    
    func testReceiptPackNil() throws {
        let receipt = DisplayReceipt(timestamp: 65481651581, replay: true, sendAttempt: 6585, od: nil, ed: nil)
        XCTAssertNotNil(receipt)
        
        let packedData = try receipt.pack()
        XCTAssertNotNil(packedData);
        
        XCTAssertEqual("cf0000000f3f02b57dc3cd19b9c0c0", packedData.hexString());
    }
    
    func testReceiptUnpackNil() throws {
     
        let packedData = Data(hexString: "cf0000000f3f02b57dc3cd19b9c0c0")
        let unpackedReceipt = try DisplayReceipt.unpack(from: packedData!)
        XCTAssertNotNil(unpackedReceipt)
        
        XCTAssertNil(unpackedReceipt.od);
        XCTAssertNil(unpackedReceipt.ed);
    }
}
