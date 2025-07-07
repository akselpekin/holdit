import SwiftUI
import Cocoa

public struct Tray: View {
    // Placeholder items to display (names). Empty shows title.
    private let items: [String]

    public init(items: [String] = []) {
        self.items = items
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
               
                Spacer(minLength: 0)
                
                let itemSize: CGFloat = 64
                let spacing: CGFloat = 12
                let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: 3)
                ScrollView {
                    if items.isEmpty {
                
                        Text("Tray")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, spacing)
                    } else {
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(items, id: \.self) { name in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.6))
                                        .frame(width: itemSize, height: itemSize)
                                    Text(name)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .frame(width: itemSize)
                                }
                            }
                        }
                        .padding(.all, spacing)
                    }
                }
            }
            Color.green // Temporary color for debugging
            .frame(width: geo.size.width, height: geo.size.height)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}