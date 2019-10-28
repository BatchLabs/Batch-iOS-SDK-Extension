//
//  BatchExtensionTests.swift
//  BatchExtensionTests
//
//  Created by Arnaud Barisain-Monrose on 23/10/2019.
//  Copyright © 2019 Batch. All rights reserved.
//

import XCTest
@testable import BatchExtension

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

}
