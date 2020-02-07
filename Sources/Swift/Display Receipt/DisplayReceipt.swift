//
//  DisplayReceipt.swift
//  BatchExtension
//
//  Copyright © 2020 Batch. All rights reserved.
//

import Foundation

internal class DisplayReceipt {
    
    let timestamp: UInt64
    var replay: Bool
    var sendAttempt: UInt32
    let od: [AnyHashable: Any?]?
    let ed: [AnyHashable: Any?]?
    
    init(timestamp: UInt64, replay: Bool, sendAttempt: UInt32, od: [AnyHashable: Any?]?, ed: [AnyHashable: Any?]?) {
        self.timestamp = timestamp
        self.replay = replay
        self.sendAttempt = sendAttempt
        self.od = od
        self.ed = ed
    }
    
    internal func pack(toWriter packer: inout MessagePackWriter) throws {
        do {
            packer.pack(timestamp)
            packer.pack(replay)
            packer.pack(sendAttempt)
            
            if let od = od, !od.isEmpty {
                try packer.packAny(od)
            } else {
                packer.packNil()
            }
            
            if let ed = ed, !ed.isEmpty {
                try packer.packAny(ed)
            } else {
                packer.packNil()
            }
        } catch {
            throw DisplayReceiptHelperError.packError(underlyingError: error)
        }
    }
    
    func pack() throws -> Data {
        var packer = MessagePackWriter()
        do {
           try pack(toWriter: &packer)
        } catch {
            throw error
        }
        return packer.data
    }
    
    class func unpack(from data: Data) throws -> DisplayReceipt {
        do {
            var reader = MessagePackReader(from: data)
            let timestamp = try reader.read(UInt64.self)
            let replay = try reader.read(Bool.self)
            let sendAttempt = try reader.read(UInt32.self)
            let od = try reader.readOptionalDictionary()
            let ed = try reader.readOptionalDictionary()
            return DisplayReceipt(timestamp: timestamp, replay: replay, sendAttempt: UInt32(sendAttempt), od: od, ed: ed)
        } catch {
           throw DisplayReceiptHelperError.unpackError(underlyingError: error)
        }
    }
}
