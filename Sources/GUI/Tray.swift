import SwiftUI
import Cocoa
import Foundation
import LOGIC

public struct Tray: View {
    
    @ObservedObject private var model: TrayModel
    @State private var isTargeted: Bool = false
    @State private var showDuplicateError: Bool = false
    @State private var selectedIDs: Set<FileItem.ID> = []
    @State private var anchorIndex: Int?
    private let topPadding: CGFloat

    public init(model: TrayModel, topPadding: CGFloat = 0) {
        self.model = model
        self.topPadding = topPadding
    }

    public var body: some View {
        GeometryReader { geo in
            let itemSize: CGFloat = 64
            let spacing: CGFloat = 12
            let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: 5)

            VStack(spacing: 0) {
                Spacer().frame(height: topPadding)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(Array(model.items.enumerated()), id: \.element.id) { idx, file in
                            VStack(spacing: 10) {
                                file.icon
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: itemSize, height: itemSize)
                                Text(file.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: itemSize)
                            }
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedIDs.contains(file.id) ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onTapGesture {
                                let shift = NSEvent.modifierFlags.contains(.shift)
                                if shift, let anchor = anchorIndex {
                                    let current = idx
                                    let start = min(anchor, current)
                                    let end = max(anchor, current)
                                    let rangeIDs = model.items[start...end].map { $0.id }
                                    selectedIDs = Set(rangeIDs)
                                } else {
                                    selectedIDs = [file.id]
                                    anchorIndex = idx
                                }
                            }
                            .onDrag {
                        
                                let provider = NSItemProvider(object: file.url as NSURL)
                                DispatchQueue.main.async {
                                    model.remove(file)
                                    selectedIDs.removeAll()
                                }
                                return provider
                            }
                            .contextMenu {
                    
                                if selectedIDs.count <= 1 {
                                    Button("Reveal in Finder") {
                                        NSApp.activate(ignoringOtherApps: true)
                                        NSWorkspace.shared.activateFileViewerSelecting([file.url])
                                    }
                                } else {
                                    Button("Reveal in Finder") {}
                                        .disabled(true)
                                }
                                
                                if selectedIDs.count > 1 {
                                    Button("Remove \(selectedIDs.count) Items") {
                                        let toRemove = model.items.filter { selectedIDs.contains($0.id) }
                                        toRemove.forEach { model.remove($0) }
                                        selectedIDs.removeAll()
                                    }
                                } else {
                                    Button("Remove from Tray") {
                                        model.remove(file)
                                        selectedIDs.removeAll()
                                    }
                                }
                            }
                         }
                    }
                    .padding(.all, spacing)
                    .animation(.easeInOut(duration: 0.2), value: model.items)
                }
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, _ in
                        guard let data = data,
                              let urlString = String(data: data, encoding: .utf8),
                              let url = URL(string: urlString) else { return }
                        DispatchQueue.main.async {
                            let newItem = FileItem(url: url)
                            let added = model.add(newItem)
                            if !added {
                       
                                showDuplicateError = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    showDuplicateError = false
                                }
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                _ = added
                            }
                        }
                    }
                    return true
                }
            }
            .background(
                Group {
                    if showDuplicateError {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.4), Color.red.opacity(0)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    } else if isTargeted {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4), Color.blue.opacity(0)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.4), Color.black.opacity(0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showDuplicateError)
                .animation(.easeInOut(duration: 0.3), value: isTargeted)
            )
            .background(.ultraThinMaterial)
            .frame(width: geo.size.width, height: geo.size.height)
            .cornerRadius(12)
            .contentShape(Rectangle())
            .onTapGesture {

                selectedIDs = []
            }
            .contextMenu {
                Button("Clear Tray") {
                    model.clear()
                }
            }
        }
    }
}