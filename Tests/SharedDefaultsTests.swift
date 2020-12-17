//
//  SharedDefaultsTests.swift
//  BatchExtension
//
//  Copyright © 2020 Batch. All rights reserved.
//

import XCTest
@testable import BatchExtension

class SharedDefaultsTests: XCTestCase {
    
    private let suiteName = "SharedDefaultsTests"
    private let sharedOptOutKey = "batch_shared_optout"
    private var defaults: UserDefaults!
    private var appInformationProvider: CustomDefaultAppInformationProvider!

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)!
        appInformationProvider = CustomDefaultAppInformationProvider(defaults: defaults)
    }
    
    func testOptOutReading() throws {
        
        // Default value, when key is missing, should be "true"
        XCTAssertTrue(try appInformationProvider.isOptOut())
        
        defaults.set(true, forKey: sharedOptOutKey)
        XCTAssertTrue(try appInformationProvider.isOptOut())
        
        defaults.set(false, forKey: sharedOptOutKey)
        XCTAssertFalse(try appInformationProvider.isOptOut())
    }
}

private struct CustomDefaultAppInformationProvider: AppInformationProvider {
    
    var defaults: UserDefaults
    
    func sharedDefaults() throws -> UserDefaults {
        return defaults
    }
}
