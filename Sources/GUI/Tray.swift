import SwiftUI
import Cocoa
import Foundation

public struct Tray: View {
    
    @ObservedObject private var model: TrayModel
    @State private var isTargeted: Bool = false
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
                        ForEach(model.items) { file in
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
                        }
                    }
                    .padding(.all, spacing)
                }
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, _ in
                        guard let data = data,
                              let urlString = String(data: data, encoding: .utf8),
                              let url = URL(string: urlString) else { return }
                        DispatchQueue.main.async {
                            model.add(FileItem(url: url))
                        }
                    }
                    return true
                }
            }
            .background(isTargeted ? Color.blue : Color.clear)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .contextMenu {
                Button("Clear Tray") {
                    model.clear()
                }
            }
        }
    }
}