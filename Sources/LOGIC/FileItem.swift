import Foundation
import SwiftUI

public struct FileItem: Identifiable, Hashable {
    public let id = UUID()
    public let url: URL

    public var name: String { url.lastPathComponent }

    @MainActor
    private static var iconCache = NSCache<NSString, NSImage>()

    @MainActor
    public var icon: Image {
        let key = url.path as NSString
        if let cached = FileItem.iconCache.object(forKey: key) {
            return Image(nsImage: cached)
        }
        let nsImage = NSWorkspace.shared.icon(forFile: url.path)
        nsImage.size = NSSize(width: 64, height: 64)
        FileItem.iconCache.setObject(nsImage, forKey: key)
        return Image(nsImage: nsImage)
    }

    public init(url: URL) {
        self.url = url
    }
}

// Sendable for async closures
extension FileItem: @unchecked Sendable {}
