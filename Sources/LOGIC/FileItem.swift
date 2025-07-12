import Foundation
import SwiftUI

public struct FileItem: Identifiable, Hashable {
    public let id: UUID

    private let storedURL: URL
    private let bookmarkData: Data

    public var name: String { url.lastPathComponent }

    @MainActor
    private static var iconCache = NSCache<NSString, NSImage>()

    @MainActor
    public var icon: Image {
        let url = resolvedURL
        let key = url.path as NSString
        if let cached = FileItem.iconCache.object(forKey: key) {
            return Image(nsImage: cached)
        }
        
        var image: NSImage
        if url.startAccessingSecurityScopedResource() {
            image = NSWorkspace.shared.icon(forFile: url.path)
            url.stopAccessingSecurityScopedResource()
        } else {
            image = NSWorkspace.shared.icon(forFile: url.path)
        }
        image.size = NSSize(width: 64, height: 64)
        FileItem.iconCache.setObject(image, forKey: key)
        return Image(nsImage: image)
    }

    public init(url: URL) {
        self.id = UUID()
        self.storedURL = url
     
        if let data = try? url.bookmarkData(options: [.withSecurityScope],
                                           includingResourceValuesForKeys: nil,
                                           relativeTo: nil) {
            self.bookmarkData = data
        } else {
            self.bookmarkData = Data()
        }
    }

    // Resolve the bookmark into a usable URL, fallback to storedURL
    private var resolvedURL: URL {
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: bookmarkData,
                               options: [.withSecurityScope],
                               relativeTo: nil,
                               bookmarkDataIsStale: &isStale) {
            return url
        }
        return storedURL
    }
    
    // Public URL property
    public var url: URL { resolvedURL }
}

// Sendable for async closures
extension FileItem: @unchecked Sendable {}
