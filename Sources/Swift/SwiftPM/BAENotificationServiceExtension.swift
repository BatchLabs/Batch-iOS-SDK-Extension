//
//  BAENotificationServiceExtension.swift
//  BatchExtension
//
//  Copyright © 2019 Batch. All rights reserved.
//

#if BATCHEXTENSION_PURE_SWIFT

import Foundation
import UserNotifications

/**
Drop-in replacement for UNNotificationServiceExtension.

Simply set it as your base class without overriding any methods and Batch will automatically:
 - Download and set rich content
 - Send display receipts
 
 This pure swift implementation is only imported when using SwiftPM to use BatchExtension. Due to it being a Swift class, it cannot be overriden in Objective-C.
 If you need this, either reimplement it or use Cocoapods/Carthage to add this extension.
 
 Note: This class is a temporary workaround until SwiftPM handles mixed language packages better
*/

open class BAENotificationServiceExtension: UNNotificationServiceExtension {
    let richNotificationHelper = RichNotificationHelper()
    let displayReceiptHelper = DisplayReceiptHelper()
    
    override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        richNotificationHelper.didReceive(request, withContentHandler: contentHandler)
        displayReceiptHelper.didReceive(request)
    }
    
    override open func serviceExtensionTimeWillExpire() {
        richNotificationHelper.serviceExtensionTimeWillExpire()
        displayReceiptHelper.serviceExtensionTimeWillExpire()
    }
}

#endif
