//
//  DisplayReceiptHelper.swift
//  BatchExtension
//
//  Copyright © 2020 Batch. All rights reserved.
//

import Foundation
import UserNotifications

@objc(BAEDisplayReceiptHelper)
@objcMembers
public class DisplayReceiptHelper : NSObject {
    
    /**
     Send the display receipt to Batch server if necessary.
     
     This operation can finish after serviceExtensionTimeWillExpire, so be sure to handle this case correctly, and preprocess your content before giving it to this method
     
     - Parameter content: Notification content
     - Parameter completionHandler: Completion block
     */
    public func processDisplayReceipt(forContent content: UNNotificationContent, completionHandler: @escaping ((UNNotificationContent?, Error?) -> Void)) {
        do {
            let receipt = try displayReceipt(fromPayload: content.userInfo)
            try save(receipt)
            //try send()
            completionHandler(content, nil)
        } catch {
            completionHandler(content, error)
        }
    }
    
    //MARK: UNUserNotificationServiceExtension methods
    
    /**
     Cache and send display receipts
     
     This operation can finish after serviceExtensionTimeWillExpire, so be sure to handle this case correctly
     */
    @objc(didReceiveNotificationRequest:)
    public func didReceive(_ request: UNNotificationRequest) {
        
        do {
            if try DisplayReceiptCacheHelper.isOptOut() {
                print("Batch - SDK is opt-out, skipping display receipts")
                return
            }
        } catch {
            print("Batch - An error occurred while processing display receipts: \(error)")
        }
        
        processDisplayReceipt(forContent: request.content) { (content: UNNotificationContent?, error: Error?) in
            if let error = error {
                print("Batch - An error occurred while processing display receipts: \(error)")
            }
        }
    }
    
    /**
     Call this to notify Batch that the same method of the standard iOS delegate has been called
    */
    public func serviceExtensionTimeWillExpire() {
        // Nothing here yet. We might use this in the future.
    }
}

public enum DisplayReceiptHelperError: Error, CustomNSError {
    case noReceiptDataFound
    case invalidReceiptDataPayload
    case readCacheError(underlyingError: Error)
    case writeCacheError(underlyingError: Error)
    case packError(underlyingError: Error)
    case unpackError(underlyingError: Error)
    case appGroupError
    case unknownError
    
    public var localizedDescription: String {
        switch self {
        case .noReceiptDataFound:
            return "No receipt data found in the notification content"
        case .invalidReceiptDataPayload:
            return "Receive receipt data in the notification content are invalid"
        case .readCacheError:
            return "Error when reading value from shared cache"
        case .writeCacheError:
            return "Error when writing value to shared cache"
        case .packError:
            return "Error when packing receipt"
        case .unpackError:
            return "Error when unpacking receipt"
        case .appGroupError:
                return "Could not get app group folder"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    public static var errorDomain: String {
        return Consts.receiptErrorDomain
    }
    
    public var errorUserInfo: [String : Any] {
        var info: [String : Any] = [
            NSLocalizedDescriptionKey: self.localizedDescription
        ]
        
        if case .readCacheError(let underlyingError) = self {
            info[NSUnderlyingErrorKey] = underlyingError as NSError
        }
        
        if case .writeCacheError(let underlyingError) = self {
            info[NSUnderlyingErrorKey] = underlyingError as NSError
        }
        
        return info
    }
}

//MARK: -
//MARK: Private methods
extension DisplayReceiptHelper {
     // TODO prod url
    static let displayReceiptUrl = URL(string: "https://drws.batch.com/i/" + Consts.receiptSchemaVersion)!
    
    func eventData(_ batchPayload: [AnyHashable: Any]) -> [AnyHashable : Any] {
        var eventData = [AnyHashable: Any]()
        if let i = batchPayload["i"] {
            eventData["i"] = i
        }
        
        if let ex = batchPayload["ex"] {
            eventData["ex"] = ex
        }
        
        if let va = batchPayload["va"] {
            eventData["va"] = va
        }
        
        return eventData
    }
    
    func displayReceipt(fromPayload payload: [AnyHashable: Any]) throws -> DisplayReceipt {
        if let batchPayload = payload["com.batch"] as? [AnyHashable : Any],
            let receiptPayload = batchPayload["r"] as? [AnyHashable : Any],
            let receiptMode = receiptPayload["m"] as? Int {
            
            if receiptMode > 2 || receiptMode < 0 {
                throw DisplayReceiptHelperError.invalidReceiptDataPayload
            }
            
            let currentTimestamp = UInt64(NSDate().timeIntervalSince1970)
            if receiptMode == 1 || receiptMode == 2 {
                let od = batchPayload["od"] as? [AnyHashable : Any]
                let ed = eventData(batchPayload)
                return DisplayReceipt(timestamp: currentTimestamp, replay: false, sendAttempt: 0, od: od, ed: ed)
            }
        }

        throw DisplayReceiptHelperError.noReceiptDataFound
    }
    
    func save(_ receipt: DisplayReceipt) throws {
        let data = try receipt.pack()
        try DisplayReceiptCacheHelper.write(data)
    }
    
    func send() throws {
        // Read receipt in cache
        var packer = MessagePackWriter()
        let cachedFiles = try DisplayReceiptCacheHelper.cachedFiles()
        var receipts = [MessagePackFlatValue]()
        
        for file in cachedFiles {
            do {
                // Read and update cached receipt
                let data = try DisplayReceiptCacheHelper.read(fromFile: file)
                let receipt = try DisplayReceipt.unpack(from: data)
                receipt.sendAttempt += receipt.sendAttempt + 1
                receipt.replay = false
                
                // Re-pack, add to body and re-save
                let tmpData = try MessagePackFlatValue {
                    try receipt.pack(toWriter: &$0)
                }
                try DisplayReceiptCacheHelper.write(toFile: file, tmpData.data)
            
                receipts.append(tmpData)
            } catch {
                // Error during unpack/pack, ignore the receipt
            }
        }

        if receipts.count <= 0 {
            // Nothing to send
            return
        }
        
        try packer.packFlatArray(receipts)
        
        // Send body
        let data = packer.data
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForResource = TimeInterval(Consts.timeoutIntervalSecs)
        let session = URLSession(configuration: urlSessionConfiguration)
        
        var request = URLRequest(url: DisplayReceiptHelper.displayReceiptUrl)
        request.httpMethod = "POST"
        request.addValue(Consts.receiptSchemaVersion, forHTTPHeaderField: Consts.receiptHeaderSchemaVersion)
        request.addValue("1.0.0-swift", forHTTPHeaderField: Consts.receiptHeaderExtVersion)
        
        let task = session.uploadTask(with: request, from: data,
                                      completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            let httpResponse = response as? HTTPURLResponse
            if httpResponse != nil && httpResponse!.statusCode >= 200 && httpResponse!.statusCode <= 399 {
                // Request is successful - delete cached files
                for file in cachedFiles {
                    let _ = DisplayReceiptCacheHelper.delete(file)
                }
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

