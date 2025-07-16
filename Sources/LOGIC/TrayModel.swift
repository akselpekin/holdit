import Foundation
import Combine

@MainActor
public class TrayModel: ObservableObject {
    @Published public private(set) var items: [FileItem]

    private var pathSet = Set<String>()

    public init(initialItems: [FileItem] = []) {
        self.items = initialItems
        pathSet = Set(initialItems.map { $0.url.path })
    }

    public func add(_ item: FileItem) -> Bool {
        let newPath = item.url.path
        guard !pathSet.contains(newPath) else { return false }
        items.append(item)
        pathSet.insert(newPath)
        return true
    }

    public func clear() {
        items.removeAll()
        pathSet.removeAll()
    }

    public func remove(_ item: FileItem) {
        items.removeAll { $0.id == item.id }
        pathSet.remove(item.url.path)
    }


    public func sanityCheck() {
       
        let currentItems = items
       
        DispatchQueue.global(qos: .utility).async {

            let parentDirs = Set(currentItems.map { URL(fileURLWithPath: $0.url.path).deletingLastPathComponent() })
            var dirCache = [URL: [URL]]()
            for dir in parentDirs {
                if let files = try? FileManager.default.contentsOfDirectory(at: dir,
                                                                           includingPropertiesForKeys: nil,
                                                                           options: [.skipsHiddenFiles]) {
                    dirCache[dir] = files
                }
            }
       
            let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey]
            var existenceMap = [String: Bool]()
            for item in currentItems {
                let url = item.url
                let isFile = (try? url.resourceValues(forKeys: resourceKeys).isRegularFile) ?? false
                existenceMap[url.path] = isFile
            }
         
            var buffer = [FileItem]()
            buffer.reserveCapacity(currentItems.count)
            var seen = Set<String>()
            for item in currentItems {
                let path = item.url.path
                var candidate: FileItem?
                if existenceMap[path] ?? false {
                    candidate = item
                } else {
                    let parentDir = URL(fileURLWithPath: path).deletingLastPathComponent()
                    if let files = dirCache[parentDir],
                       let match = files.first(where: { $0.lastPathComponent == item.url.lastPathComponent }) {
                        candidate = FileItem(url: match)
                    }
                }
                if let itemToAdd = candidate {
                    let p = itemToAdd.url.path
                    if !seen.contains(p) {
                        seen.insert(p)
                        buffer.append(itemToAdd)
                    }
                }
            }
            let oldPaths = currentItems.map { $0.url.path }
            let newPaths = buffer.map { $0.url.path }
            guard newPaths != oldPaths else { return }
             DispatchQueue.main.async {
                 self.items = buffer
                 self.pathSet = Set(buffer.map { $0.url.path })
            }
        }
    }
}