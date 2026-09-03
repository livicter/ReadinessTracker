import SwiftUI

/// Whoop-style journal entry for tracking habits and their correlation with recovery
struct JournalEntryView: View {
    @State private var selectedBehaviors: Set<Behavior> = []
    @State private var notes: String = ""
    let onSave: ([Behavior], String) -> Void
    
    enum Behavior: String, CaseIterable, Identifiable {
        case alcohol = "Alcohol"
        case caffeineLate = "Late Caffeine"
        case screenTime = "Late Screen Time"
        case stress = "High Stress"
        case travel = "Travel"
        case sick = "Feeling Sick"
        case massage = "Massage/Therapy"
        case iceBath = "Ice Bath"
        case sauna = "Sauna"
        case meditation = "Meditation"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .alcohol: return "wineglass.fill"
            case .caffeineLate: return "cup.and.saucer.fill"
            case .screenTime: return "iphone"
            case .stress: return "exclamationmark.triangle.fill"
            case .travel: return "airplane"
            case .sick: return "facemask.fill"
            case .massage: return "hands.sparkles.fill"
            case .iceBath: return "snowflake"
            case .sauna: return "flame.fill"
            case .meditation: return "brain.head.profile"
            }
        }
        
        var color: Color {
            switch self {
            case .alcohol, .caffeineLate, .screenTime, .stress, .travel, .sick:
                return RTColor.warning
            case .massage, .iceBath, .sauna, .meditation:
                return RTColor.optimal
            }
        }
        
        var category: String {
            switch self {
            case .alcohol, .caffeineLate, .screenTime:
                return "Negative"
            case .stress, .travel, .sick:
                return "Stressors"
            case .massage, .iceBath, .sauna, .meditation:
                return "Recovery"
            }
        }
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Journal Entry")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    
                    Spacer()
                    
                    Text("\(selectedBehaviors.count) selected")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
                
                // Behavior toggles grouped by category
                let grouped = Dictionary(grouping: Behavior.allCases) { $0.category }
                let categories = ["Negative", "Stressors", "Recovery"]
                
                ForEach(categories, id: \.self) { category in
                    if let behaviors = grouped[category] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                                .textCase(.uppercase)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(behaviors) { behavior in
                                    BehaviorToggle(
                                        behavior: behavior,
                                        isSelected: selectedBehaviors.contains(behavior)
                                    ) {
                                        if selectedBehaviors.contains(behavior) {
                                            selectedBehaviors.remove(behavior)
                                        } else {
                                            selectedBehaviors.insert(behavior)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                    
                    TextEditor(text: $notes)
                        .font(.subheadline)
                        .foregroundStyle(RTColor.primaryText)
                        .frame(height: 80)
                        .padding(8)
                        .background(RTColor.surfaceHighlight)
                        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
                }
                
                // Save button
                Button {
                    Haptic.success()
                    onSave(Array(selectedBehaviors), notes)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Entry")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RTColor.optimal)
                    .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
                }
                .disabled(selectedBehaviors.isEmpty && notes.isEmpty)
                .opacity(selectedBehaviors.isEmpty && notes.isEmpty ? 0.5 : 1)
            }
        }
    }
}

private struct BehaviorToggle: View {
    let behavior: JournalEntryView.Behavior
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptic.tap()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: behavior.icon)
                    .font(.system(size: 12))
                Text(behavior.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : RTColor.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? behavior.color : RTColor.surfaceHighlight)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Simple flow layout for wrapping tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}