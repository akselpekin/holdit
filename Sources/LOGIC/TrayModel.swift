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
            // Attempt to re-link or remove missing files
            var updated = currentItems
            for (index, item) in currentItems.enumerated().reversed() {
                let path = item.url.path
                if !FileManager.default.fileExists(atPath: path) {
                    // try to find a file with same name in parent directory
                    let parentDir = URL(fileURLWithPath: path).deletingLastPathComponent()
                    if let files = try? FileManager.default.contentsOfDirectory(at: parentDir,
                                                                               includingPropertiesForKeys: nil,
                                                                               options: [.skipsHiddenFiles]),
                       let match = files.first(where: { $0.lastPathComponent == item.url.lastPathComponent }) {
                        // re-link moved/renamed file
                        updated[index] = FileItem(url: match)
                    } else {
                        // remove if truly missing
                        updated.remove(at: index)
                    }
                }
            }
            // Remove duplicate paths
            var seen = Set<String>()
            let uniqueItems = updated.filter { item in
                let p = item.url.path
                if seen.contains(p) { return false }
                seen.insert(p)
                return true
            }
            guard uniqueItems.count != currentItems.count else { return }
            DispatchQueue.main.async {
                self.items = uniqueItems
                self.pathSet = Set(uniqueItems.map { $0.url.path })
            }
        }
    }
}