//
//  DisplayReceiptCacheHelper.swift
//  BatchExtension
//
//  Copyright © 2020 Batch. All rights reserved.
//

import Foundation

internal struct DisplayReceiptCacheHelper {
    
    private static let coordinator = NSFileCoordinator(filePresenter: nil)
        
    static func sharedGroupId() throws -> String {
        
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

    static func sharedDirectory() throws -> URL {
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
    
    static func sharedDefaults() throws -> UserDefaults {
        let groupId = try self.sharedGroupId()
        guard let defaults = UserDefaults.init(suiteName: groupId)
        else { throw DisplayReceiptHelperError.appGroupError }
        return defaults
    }
    
    // MARK: Methods updating cache files
    
    static func newFilename() -> String {
        return String(format: Consts.receiptCacheFileFormat, UUID().uuidString)
    }
    
    static func write(toFile file: URL, _ data: Data) throws {
        var error: NSError?
        var writeError: Error?
        coordinator.coordinate(writingItemAt: file, options: .forReplacing, error: &error) { url in
            do {
                try data.write(to: url)
            } catch {
                writeError = error
            }
        }
        
        if writeError != nil || error != nil {
            throw DisplayReceiptHelperError.writeCacheError(underlyingError: writeError ?? error!)
        }
    }
    
    static func write(_ data: Data) throws {
        do {
            let cacheDir = try sharedDirectory()
            let cacheFile = cacheDir.appendingPathComponent(newFilename())
            
            try write(toFile: cacheFile, data)
        } catch {
            throw DisplayReceiptHelperError.writeCacheError(underlyingError: error)
        }
    }
    
    static func read(fromFile file: URL) throws -> Data {
        var error: NSError?
        var data: Data?
        coordinator.coordinate(readingItemAt: file, options: .withoutChanges, error: &error) { url in
            do {
                data = try Data(contentsOf: file)
            } catch {
                // Ignore
            }
        }
        
        if data != nil {
            return data!
        }
        throw DisplayReceiptHelperError.readCacheError(underlyingError: error ?? NSError())
    }
    
    static func delete(_ file: URL) -> Error? {
        var error: NSError?
        var deleteError: Error?
        coordinator.coordinate(writingItemAt: file, options: .forDeleting, error: &error) { url in
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                deleteError = error
            }
        }
        
        if deleteError != nil || error != nil {
            return DisplayReceiptHelperError.writeCacheError(underlyingError: deleteError ?? error!)
        }
        return nil
    }
    
    static func cachedFiles() throws -> [URL] {
        do {
            let cacheDir = try sharedDirectory()
            let urls = try FileManager.default.contentsOfDirectory(at: cacheDir,
                                                                   includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey, .isReadableKey],
                                                                   options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

            var files:[URL:Date] = [:]
            for url in urls {
                let fileAttributes = try url.resourceValues(forKeys:[.isRegularFileKey, .creationDateKey, .isReadableKey])
                if fileAttributes.isRegularFile ?? false && fileAttributes.isReadable ?? false && fileAttributes.creationDate != nil {
                    if fileAttributes.creationDate!.timeIntervalSinceNow > Consts.receiptMaxAgeFromCache * -1.0 {
                        files[url] = fileAttributes.creationDate
                    } else {
                        // file is not too old, delete it
                        let _ = delete(url)
                    }
                }
            }
            
            if files.count <= 0 {
                return []
            }
            
            let output = files.sorted { $0.1 > $1.1 }.map { $0.0 }.prefix(Consts.receiptMaxCacheFile)
            return Array(output)
        } catch {
            throw DisplayReceiptHelperError.readCacheError(underlyingError: error)
        }
    }
    
    // MARK: Methods reading user defaults

    static func isOptOut() throws -> Bool {
        let defaults = try self.sharedDefaults()
        if defaults.object(forKey: "batch_shared_optout") != nil {
            // Key is missing, we don't send display receipt
            return true
        }
        return defaults.bool(forKey: "batch_shared_optout")
    }
}
