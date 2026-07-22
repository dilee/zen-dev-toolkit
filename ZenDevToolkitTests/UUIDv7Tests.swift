//
//  UUIDv7Tests.swift
//  ZenDevToolkitTests
//
//  Created by Dileesha Rajapakse on 2026-07-22.
//

import Foundation
import Testing
@testable import ZenDevToolkit

struct UUIDv7Tests {

    @Test func versionNibbleIsSeven() {
        let characters = Array(UUIDv7.generate().uuidString)
        #expect(characters[14] == "7")
    }

    @Test func variantNibbleIsRFC9562() {
        let characters = Array(UUIDv7.generate().uuidString)
        // The variant nibble encodes 10xx, i.e. one of 8, 9, A or B.
        #expect("89ABab".contains(characters[19]))
    }

    @Test func embedsTimestampMilliseconds() {
        // 0.123456s carries sub-millisecond precision that must truncate to 123ms.
        let injected = Date(timeIntervalSince1970: 1_700_000_000.123456)
        let uuid = UUIDv7.generate(timestamp: injected)
        #expect(embeddedMilliseconds(of: uuid) == 1_700_000_000_123)
    }

    @Test func timeOrderedUUIDsSortAscending() {
        let earlier = UUIDv7.generate(timestamp: Date(timeIntervalSince1970: 1_700_000_000.000))
        let later = UUIDv7.generate(timestamp: Date(timeIntervalSince1970: 1_700_000_000.010))
        #expect(earlier.uuidString < later.uuidString)
    }

    @Test func roundTripsThroughUUIDString() {
        let uuid = UUIDv7.generate()
        #expect(UUID(uuidString: uuid.uuidString) == uuid)
    }

    // Decodes the leading 48 bits (bytes 0-5) back into epoch milliseconds.
    private func embeddedMilliseconds(of uuid: UUID) -> UInt64 {
        let bytes = uuid.uuid
        return (UInt64(bytes.0) << 40)
            | (UInt64(bytes.1) << 32)
            | (UInt64(bytes.2) << 24)
            | (UInt64(bytes.3) << 16)
            | (UInt64(bytes.4) << 8)
            | UInt64(bytes.5)
    }
}
