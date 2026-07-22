//
//  Base64ImageTests.swift
//  ZenDevToolkitTests
//
//  Created by Dileesha Rajapakse on 2026-07-22.
//

import Foundation
import Testing
@testable import ZenDevToolkit

struct Base64ImageTests {

    // MARK: - stripDataURIPrefix

    @Test func stripsPNGDataURIHeader() {
        #expect(stripDataURIPrefix("data:image/png;base64,AAAA") == "AAAA")
    }

    @Test func stripsMimelessDataURIHeader() {
        #expect(stripDataURIPrefix("data:;base64,AAAA") == "AAAA")
    }

    @Test func stripsHeaderWithMimeParameters() {
        #expect(stripDataURIPrefix("data:image/svg+xml;charset=utf-8;base64,AAAA") == "AAAA")
    }

    @Test func matchesHeaderCaseInsensitively() {
        #expect(stripDataURIPrefix("DATA:image/PNG;BASE64,AAAA") == "AAAA")
    }

    @Test func leavesPlainBase64Unchanged() {
        #expect(stripDataURIPrefix("AAAABBBBCCCC") == "AAAABBBBCCCC")
    }

    @Test func leavesNonBase64DataURIUnchanged() {
        // No ";base64" marker, so the payload must be left untouched.
        let input = "data:text/plain,hello world"
        #expect(stripDataURIPrefix(input) == input)
    }

    @Test func toleratesSurroundingWhitespace() {
        #expect(stripDataURIPrefix("   data:image/png;base64,AAAA   ") == "AAAA")
    }

    // MARK: - Output display truncation

    @Test func shortOutputIsNotTruncated() {
        let (display, full) = Base64View.displayTruncation(of: "hello", limit: 10)
        #expect(display == "hello")
        #expect(full == nil)
    }

    @Test func outputAtLimitIsNotTruncated() {
        let text = String(repeating: "A", count: 10)
        let (display, full) = Base64View.displayTruncation(of: text, limit: 10)
        #expect(display == text)
        #expect(full == nil)
    }

    @Test func oversizedOutputIsTruncatedForDisplayOnly() {
        let text = String(repeating: "A", count: 15)
        let (display, full) = Base64View.displayTruncation(of: text, limit: 10)
        #expect(display.count == 10)
        #expect(full == text)
    }

    // MARK: - Image sniffing

    // 1×1 transparent PNG.
    private static let onePixelPNGBase64 =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="

    @Test func sniffsRealPNGFixture() throws {
        let data = try #require(Data(base64Encoded: Base64ImageTests.onePixelPNGBase64))
        #expect(ImageFormat(sniffing: data) == .png)
    }

    @Test func sniffsJPEGHeaderBytes() {
        // FF D8 FF E0 is the JFIF variant; only the first three bytes are load-bearing.
        let data = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46])
        #expect(ImageFormat(sniffing: data) == .jpeg)
    }

    @Test func sniffsGIFHeader() {
        let data = Data("GIF89a".utf8) + Data([0x00, 0x00])
        #expect(ImageFormat(sniffing: data) == .gif)
    }

    @Test func nonImageTextReturnsNil() {
        #expect(ImageFormat(sniffing: Data("hello".utf8)) == nil)
    }

    @Test func emptyDataReturnsNil() {
        #expect(ImageFormat(sniffing: Data()) == nil)
    }

    @Test func shortDataDoesNotCrash() {
        #expect(ImageFormat(sniffing: Data([0x00, 0x01])) == nil)
    }

    // MARK: - Format metadata

    @Test func pngMetadata() {
        #expect(ImageFormat.png.displayName == "PNG")
        #expect(ImageFormat.png.fileExtension == "png")
    }

    @Test func jpegMetadata() {
        #expect(ImageFormat.jpeg.displayName == "JPEG")
        #expect(ImageFormat.jpeg.fileExtension == "jpg")
    }
}
