import Foundation
import Combine

@MainActor
public class TrayModel: ObservableObject {
    @Published public private(set) var items: [FileItem]

    private var pathSet = Set<String>()
    private var idSet = Set<String>()

    public init(initialItems: [FileItem] = []) {
        self.items = initialItems
        pathSet = Set(initialItems.map { $0.url.path })
        idSet = Set(initialItems.compactMap { $0.fsID })
    }

    public func add(_ item: FileItem) -> Bool {
        if let id = item.fsID {
            if idSet.contains(id) { return false }
        } else if pathSet.contains(item.url.path) {
            return false
        }
        items.append(item)
        pathSet.insert(item.url.path)
        if let id = item.fsID { idSet.insert(id) }
        return true
    }

    public func clear() {
        items.removeAll()
        pathSet.removeAll()
        idSet.removeAll()
    }

    public func remove(_ item: FileItem) {
        items.removeAll { $0.id == item.id }
        pathSet.remove(item.url.path)
        if let id = item.fsID { idSet.remove(id) }
    }

    private var isChecking = false

    public func sanityCheck() {
        guard !isChecking else {
            print("TrayModel: sanity check skipped (already running)")
            return
        }
        isChecking = true
        print("TrayModel: is checking...")
       
        let currentItems = items
        let knownPaths = pathSet
       
        DispatchQueue.global(qos: .utility).async {
            defer {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.isChecking = false
                }
            }

            var buffer = [FileItem]()
            buffer.reserveCapacity(currentItems.count)
            var seen = Set<String>()
            for item in currentItems {
                let url = item.url
                let isReachable = (try? url.checkResourceIsReachable()) ?? false
                
                guard isReachable else { continue }
                let p = url.path
                if !seen.contains(p) {
                    seen.insert(p)
                   
                    buffer.append(item)
                }
            }
            
            let newPaths = Set(buffer.map { $0.url.path })
            
            if newPaths != knownPaths || buffer.count != currentItems.count {
                 DispatchQueue.main.async {
                     self.items = buffer
                     self.pathSet = newPaths
                     self.idSet = Set(buffer.compactMap { $0.fsID })
                }
            }
        }
    }

}