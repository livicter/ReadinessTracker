import SwiftUI

/// Apple Fitness–style floating frosted pill tab bar (Honest #54).
struct FloatingPillTabBar: View {
    @Binding var selection: Int

    private struct Item: Identifiable {
        let id: Int
        let title: String
        let systemImage: String
    }

    private let items: [Item] = [
        .init(id: 0, title: "Today", systemImage: "gauge.with.dots.needle.67percent"),
        .init(id: 1, title: "History", systemImage: "chart.line.uptrend.xyaxis"),
        .init(id: 2, title: "Check-in", systemImage: "checkmark.circle"),
        .init(id: 3, title: "Settings", systemImage: "gearshape")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    Haptic.selectionChanged()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = item.id
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18, weight: selection == item.id ? .semibold : .regular))
                            .symbolVariant(selection == item.id ? .fill : .none)
                            .frame(width: 44, height: 28)
                            .background(
                                Capsule()
                                    .fill(selection == item.id ? RTColor.optimal.opacity(0.16) : Color.clear)
                            )
                        Text(item.title)
                            .font(.caption2.weight(selection == item.id ? .semibold : .medium))
                    }
                    .foregroundStyle(selection == item.id ? RTColor.optimal : RTColor.secondaryText)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selection == item.id ? .isSelected : [])
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main tabs")
    }
}
