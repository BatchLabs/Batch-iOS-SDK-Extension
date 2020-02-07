//
//  Consts.swift
//  BatchExtension
//
//  Copyright © 2019 Batch. All rights reserved.
//

import Foundation

struct Consts {
    static let timeoutIntervalSecs = 20
    static let attachmentIdentifier = "batch_rich_attachment"
    static let errorDomain = "com.batch.extension.richnotificationhelper"
    
    static let receiptAppGroupDirectory = "group.com.batch.enterprise"
    static let receiptCacheDirectory = "com.batch.displayreceipts"
    static let receiptCacheFileFormat = "%@.bin"
    static let receiptMaxCacheFile = 5
    static let receiptMaxAgeFromCache = 2592000.0 // 30 days in seconds
    static let receiptHeaderExtVersion = "x-batch-ext-version"
    static let receiptHeaderSchemaVersion = "x-batch-protocol-version"
    static let receiptSchemaVersion = "1.0.0"
    static let receiptErrorDomain = "com.batch.extension.displayreceipthelper"
}
