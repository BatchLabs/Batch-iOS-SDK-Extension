//
//  RichNotificationHelper.swift
//  BatchExtension
//
//  Copyright © 2019 Batch. All rights reserved.
//

import Foundation
import UserNotifications

/**
 Batch Extension Rich Notifications helper.

 You should instanciate this once per UNNotificationServiceExtension and use the same instance for everything, as some methods might need context.
 */
@objc(BAERichNotificationHelper)
@objcMembers
public class RichNotificationHelper : NSObject {
    
    /**
     Allow the extension to fetch rich notification centent in iOS 13's
     low data mode.
     Default: false
     */
    public static var allowInLowDataMode = false
    
    /**
     Append rich data (image/sound/video/...) to a specified notification content. Batch will automatically download the attachments and add them to the content
     before returning it to you in the completion handler.
     
     This operation can finish after serviceExtensionTimeWillExpire, so be sure to handle this case correctly, and preprocess your content before giving it to this method
     
     - Parameter content: Notification content
     - Parameter completionHandler: Completion block
     */
    public func appendRichData(toContent content: UNNotificationContent, completionHandler: @escaping ((UNNotificationContent?, Error?) -> Void)) {
        
        do {
            // Download rich content
            let attachment = try self.attachment(forPayload: content.userInfo)
            download(attachment: attachment) { (result: Result<DownloadedAttachment, Error>) in
                do {
                    let downloadedAttachment = try result.get()
                    let notificationAttachment = try UNNotificationAttachment(identifier: Consts.attachmentIdentifier,
                                                                          url: downloadedAttachment.fileUrl,
                                                                          options: [UNNotificationAttachmentOptionsTypeHintKey: attachment.type])
                    guard let mutableContent = (content.mutableCopy() as? UNMutableNotificationContent) else {
                        completionHandler(content, RichDataError.unknownError)
                        return
                    }
                    
                    mutableContent.attachments.append(notificationAttachment)
                    completionHandler(mutableContent, nil)
                } catch {
                    completionHandler(content, error)
                }
            }
        } catch {
            completionHandler(content, error)
        }
    }
    
    //MARK: UNUserNotificationServiceExtension methods
    
    /**
     Drop-in replacement for UserNotifications' didReceiveNotificationRequest:withContentHandler.
     Feel free to tweak the request or the result before handing it to Batch.
     
     - Parameter request: Notification request
     - Parameter contentHandler: Callback block
     */
    @objc(didReceiveNotificationRequest:withContentHandler:)
    public func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        appendRichData(toContent: request.content) { (content: UNNotificationContent?, error: Error?) in
            if let error = error {
                print("Batch - An error occurred while downloading the rich push content: \(error)")
            }
            contentHandler(content ?? request.content)
        }
    }
    
    /**
    Call this to notify Batch that the same method of the standard iOS delegate has been called
    */
    public func serviceExtensionTimeWillExpire() {
        // Nothing here yet. We might use this in the future.
    }
}

public enum RichDataError: Error, CustomNSError {
    case noRichDataFound
    case invalidRichDataPayload
    case downloadError(underlyingError: Error)
    case unknownDownloadError
    case unknownError
    
    public var localizedDescription: String {
        switch self {
        case .noRichDataFound:
            return "No additional data to append found"
        case .invalidRichDataPayload:
            return "The rich data payload was invalid"
        case .downloadError:
            return "Download error. See the underlying error for more info."
        case .unknownError:
            return "Unknown error"
        case .unknownDownloadError:
            return "Unknown download error"
        }
    }
    
    public static var errorDomain: String {
        return Consts.errorDomain
    }
    
    public var errorUserInfo: [String : Any] {
        var info: [String : Any] = [
            NSLocalizedDescriptionKey: self.localizedDescription
        ]
        
        if case .downloadError(let underlyingError) = self {
            info[NSUnderlyingErrorKey] = underlyingError as NSError
        }
        
        return info
    }
}

//MARK: -
//MARK: Private methods
extension RichNotificationHelper {
    func attachment(forPayload payload: [AnyHashable : Any]) throws -> Attachment {
        if let batchPayload = payload["com.batch"] as? [AnyHashable : Any],
            let attachmentPayload = batchPayload["at"] as? [AnyHashable : Any],
            let urlString = attachmentPayload["u"] as? String,
            let type = attachmentPayload["t"] as? String {
            
            guard let url = URL(string: urlString) else {
                throw RichDataError.invalidRichDataPayload
            }
            
            return Attachment(url: url, type: type)
        }
        
        throw RichDataError.noRichDataFound
    }
    
    func download(attachment: Attachment, completionHandler: @escaping (Result<DownloadedAttachment, Error>) -> Void) {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForResource = TimeInterval(Consts.timeoutIntervalSecs)
        if #available(iOSApplicationExtension 13.0, *) {
            urlSessionConfiguration.allowsConstrainedNetworkAccess = type(of: self).allowInLowDataMode
        }
        
        let session = URLSession(configuration: urlSessionConfiguration)
        let task = session.downloadTask(with: attachment.url) { (location: URL?, _: URLResponse?, error: Error?) in
            if let error = error {
                completionHandler(.failure(RichDataError.downloadError(underlyingError: error)))
                return
            }
            
            guard let location = location else {
                completionHandler(.failure(RichDataError.unknownDownloadError))
                return
            }
            
            completionHandler(.success(DownloadedAttachment(fileUrl: location, typeHint: attachment.type)))
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

struct Attachment {
    let url: URL
    let type: String
}

struct DownloadedAttachment {
    /// Location of the URL on disk
    let fileUrl: URL
    let typeHint: String?
}
