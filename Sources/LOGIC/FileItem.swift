import Foundation
import SwiftUI

public struct FileItem: Identifiable, Hashable {
    public let id: UUID
    public let fsID: String?

    private let storedURL: URL

    public var name: String { url.lastPathComponent }

    @MainActor
    private static var iconCache = NSCache<NSString, NSImage>()

    @MainActor
    public var icon: Image {
        let url = self.url
        let key = url.path as NSString
        if let cached = FileItem.iconCache.object(forKey: key) {
            return Image(nsImage: cached)
        }
        
        let image = NSWorkspace.shared.icon(forFile: url.path)
        image.size = NSSize(width: 64, height: 64)
        FileItem.iconCache.setObject(image, forKey: key)
        return Image(nsImage: image)
    }

    public init(url: URL, id: UUID = UUID()) {
        self.id = id
        self.storedURL = url
        
        // Calculate fsID
        let fm = FileManager.default
        if let attrs = try? fm.attributesOfItem(atPath: url.path),
           let num = (attrs[.systemFileNumber] as? NSNumber)?.uint64Value,
           let dev = (attrs[.systemNumber] as? NSNumber)?.uint64Value {
            self.fsID = "\(dev):\(num)"
        } else {
            self.fsID = nil
        }
    }
    
    // Public URL property
    public var url: URL { storedURL }
}

// Sendable for async closures
extension FileItem: @unchecked Sendable {}
