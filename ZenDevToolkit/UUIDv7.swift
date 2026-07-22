//
//  UUIDv7.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2026-07-22.
//

import Foundation

/// Generator for version 7 UUIDs as defined by RFC 9562: a 48-bit Unix
/// millisecond timestamp in the leading bytes followed by random data, which
/// makes the values time-ordered while remaining ordinary 8-4-4-4-12 UUIDs.
enum UUIDv7 {
    /// Builds a version 7 UUID. The timestamp is injectable so callers (and
    /// tests) can produce deterministic, ordered values.
    static func generate(timestamp: Date = Date()) -> UUID {
        let epochMillis = UInt64(timestamp.timeIntervalSince1970 * 1000)

        var bytes = [UInt8](repeating: 0, count: 16)

        // Bytes 0-5: 48-bit big-endian Unix epoch milliseconds.
        bytes[0] = UInt8((epochMillis >> 40) & 0xFF)
        bytes[1] = UInt8((epochMillis >> 32) & 0xFF)
        bytes[2] = UInt8((epochMillis >> 24) & 0xFF)
        bytes[3] = UInt8((epochMillis >> 16) & 0xFF)
        bytes[4] = UInt8((epochMillis >> 8) & 0xFF)
        bytes[5] = UInt8(epochMillis & 0xFF)

        // Bytes 6-15: random, with the version and variant bits overwritten below.
        for index in 6..<16 {
            bytes[index] = UInt8.random(in: 0...255)
        }

        // Byte 6: version 7 in the high nibble, 4 random bits retained.
        bytes[6] = 0x70 | (bytes[6] & 0x0F)

        // Byte 8: variant (10xx) in the top two bits, 6 random bits retained.
        bytes[8] = 0x80 | (bytes[8] & 0x3F)

        let uuidBytes: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )

        return UUID(uuid: uuidBytes)
    }
}
