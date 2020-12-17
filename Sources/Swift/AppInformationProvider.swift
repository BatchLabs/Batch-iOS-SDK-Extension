//
//  AppInformationProvider.swift
//  BatchExtension
//
//  Copyright © 2020 Batch. All rights reserved.
//

import Foundation

// Protocol that defines an object that will provide application information
// such as the shared app group id, etc...
protocol AppInformationProvider {
    func sharedGroupId() throws -> String

    func sharedDirectory() throws -> URL
    
    func sharedDefaults() throws -> UserDefaults
}

public enum AppInformationProviderError: Error, CustomNSError {
    case appGroupError
    case unknownError
    
    public var localizedDescription: String {
        switch self {
        case .appGroupError:
            return "Could not get app group folder"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    public static var errorDomain: String {
        return Consts.errorDomain
    }
    
    public var errorUserInfo: [String : Any] {
        let info: [String : Any] = [
            NSLocalizedDescriptionKey: self.localizedDescription
        ]
        
        return info
    }
}

// MARK: Default implementation
extension AppInformationProvider {
    func sharedGroupId() throws -> String {
        
        let groupIdOverride = Bundle.main.object(forInfoDictionaryKey: "BATCH_APP_GROUP_ID")
        if let groupId = groupIdOverride as? String, !groupId.isEmpty {
            return groupId
        }
        
        let bundleIdentifer = Bundle.main.bundleIdentifier
        if let bundleId = bundleIdentifer, !bundleId.isEmpty {
            return "group." + bundleId + ".batch"
        }
        
        throw DisplayReceiptHelperError.appGroupError
    }

    func sharedDirectory() throws -> URL {
        do {
            guard let sharedDir = FileManager
                    .default
                    .containerURL(forSecurityApplicationGroupIdentifier: try self.sharedGroupId())?
                    .appendingPathComponent(Consts.receiptCacheDirectory)
            else { throw DisplayReceiptHelperError.appGroupError }
            
            try FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true, attributes: nil)
            return sharedDir
        } catch {
            throw DisplayReceiptHelperError.writeCacheError(underlyingError: error)
        }
    }
    
    func sharedDefaults() throws -> UserDefaults {
        let groupId = try self.sharedGroupId()
        guard let defaults = UserDefaults.init(suiteName: groupId)
        else { throw DisplayReceiptHelperError.appGroupError }
        return defaults
    }
}


struct AppInformationProviderDefaultImpl: AppInformationProvider {
}
