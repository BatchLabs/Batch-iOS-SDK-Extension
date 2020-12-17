//
//  DisplayReceiptCacheHelper.swift
//  BatchExtension
//
//  Copyright © 2020 Batch. All rights reserved.
//

import Foundation

internal struct DisplayReceiptCacheHelper {
    
    private let appInformationProvider: AppInformationProvider
    
    init(appInformationProvider injectedAppInfoProvider: AppInformationProvider = AppInformationProviderDefaultImpl()) {
        self.appInformationProvider = injectedAppInfoProvider
    }
    
    func makeCoordinator() -> NSFileCoordinator {
        return NSFileCoordinator(filePresenter: nil)
    }
    
    // MARK: Methods updating cache files
    
    func newFilename() -> String {
        return String(format: Consts.receiptCacheFileFormat, UUID().uuidString)
    }
    
    func write(toFile file: URL, _ data: Data) throws {
        var error: NSError?
        var writeError: Error?
        makeCoordinator().coordinate(writingItemAt: file, options: .forReplacing, error: &error) { url in
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
    
    func write(_ data: Data) throws {
        do {
            let cacheDir = try appInformationProvider.sharedDirectory()
            let cacheFile = cacheDir.appendingPathComponent(newFilename())
            
            try write(toFile: cacheFile, data)
        } catch {
            throw DisplayReceiptHelperError.writeCacheError(underlyingError: error)
        }
    }
    
    func read(fromFile file: URL) throws -> Data {
        var error: NSError?
        var data: Data?
        makeCoordinator().coordinate(readingItemAt: file, options: .withoutChanges, error: &error) { url in
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
    
    func delete(_ file: URL) -> Error? {
        var error: NSError?
        var deleteError: Error?
        makeCoordinator().coordinate(writingItemAt: file, options: .forDeleting, error: &error) { url in
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
    
    func cachedFiles() throws -> [URL] {
        do {
            let cacheDir = try appInformationProvider.sharedDirectory()
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

    func isOptOut() throws -> Bool {
        let defaults = try appInformationProvider.sharedDefaults()
        if defaults.object(forKey: "batch_shared_optout") != nil {
            // Key is missing, we don't send display receipt
            return true
        }
        return defaults.bool(forKey: "batch_shared_optout")
    }
}
