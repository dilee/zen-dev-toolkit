//
//  ImageDataInspector.swift
//  ZenDevToolkit
//
//  Created by Dileesha Rajapakse on 2026-07-22.
//

import Foundation
import UniformTypeIdentifiers

/// Strips a `data:<mime>;base64,` URI header from `input`, returning only the
/// Base64 payload. Plain Base64 and data URIs that lack a `;base64` marker are
/// returned unchanged. Matching is case-insensitive and tolerates surrounding
/// whitespace.
func stripDataURIPrefix(_ input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    // data:[<mediatype>][;params…];base64,<payload> — only strip when ";base64" is present.
    let pattern = "^data:[^,]*;base64,"
    if let range = trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
        return String(trimmed[range.upperBound...])
    }
    return input
}

/// A raster image format identified by sniffing the leading magic bytes of some data.
enum ImageFormat: Equatable {
    case png
    case jpeg
    case gif
    case webp
    case bmp
    case tiff
    case heic

    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        case .gif: return "GIF"
        case .webp: return "WebP"
        case .bmp: return "BMP"
        case .tiff: return "TIFF"
        case .heic: return "HEIC"
        }
    }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .gif: return "gif"
        case .webp: return "webp"
        case .bmp: return "bmp"
        case .tiff: return "tiff"
        case .heic: return "heic"
        }
    }

    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .gif: return .gif
        case .webp: return .webP
        case .bmp: return .bmp
        case .tiff: return .tiff
        case .heic: return .heic
        }
    }

    /// Identifies the image format from the leading bytes of `data`, or `nil`
    /// when they match no known format. Safe for empty or truncated data.
    init?(sniffing data: Data) {
        // Copy a bounded prefix so all indexing is 0-based and in range.
        let bytes = [UInt8](data.prefix(16))

        func matches(_ signature: [UInt8], at offset: Int) -> Bool {
            guard offset >= 0, bytes.count >= offset + signature.count else { return false }
            for (i, expected) in signature.enumerated() where bytes[offset + i] != expected {
                return false
            }
            return true
        }

        let ascii: (String) -> [UInt8] = { Array($0.utf8) }

        if matches([0x89, 0x50, 0x4E, 0x47], at: 0) {
            self = .png
        } else if matches([0xFF, 0xD8, 0xFF], at: 0) {
            self = .jpeg
        } else if matches(ascii("GIF87a"), at: 0) || matches(ascii("GIF89a"), at: 0) {
            self = .gif
        } else if matches(ascii("RIFF"), at: 0) && matches(ascii("WEBP"), at: 8) {
            self = .webp
        } else if matches(ascii("BM"), at: 0) {
            self = .bmp
        } else if matches([0x49, 0x49, 0x2A, 0x00], at: 0) || matches([0x4D, 0x4D, 0x00, 0x2A], at: 0) {
            self = .tiff
        } else if matches(ascii("ftyp"), at: 4) {
            // ISO base media file format: the major brand follows the ftyp box marker.
            let heicBrands = ["heic", "heix", "hevc", "mif1", "avif"]
            guard heicBrands.contains(where: { matches(ascii($0), at: 8) }) else { return nil }
            self = .heic
        } else {
            return nil
        }
    }
}
