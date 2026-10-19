import SwiftUI

/// Honest #500: interactive Recovery ↔ Strain dial.
/// Drag around the ring to preview balance zone shifts without leaving Today.
struct InteractiveRecoveryDialCard: View {
    let recovery: Int
    let strain: Double

    @State private var angle: Double = 0  // degrees, 0 = east, clockwise
    @State private var hasDragged = false

    private let accent = Color(hex: "BF5AF2")

    private var baseRecovery: Double { Double(recovery) }
    private var baseStrain: Double { min(21, max(0, strain)) }

    /// Map angle to recovery/strain preview deltas.
    private var previewRecovery: Int {
        let delta = sin(angle * .pi / 180) * 15
        return min(100, max(0, Int((baseRecovery + delta).rounded())))
    }

    private var previewStrain: Double {
        let delta = cos(angle * .pi / 180) * 4
        return min(21, max(0, (baseStrain + delta) * 10).rounded() / 10)
    }

    private var previewBalance: Int {
        // Mirror StrainRecoveryBalance.compute weights loosely: recovery heavy.
        let r = Double(previewRecovery)
        let sNorm = (previewStrain / 21.0) * 100
        let score = r * 0.65 + (100 - sNorm) * 0.35
        return min(100, max(0, Int(score.rounded())))
    }

    private var zone: (label: String, color: Color) {
        switch previewBalance {
        case 80...100: return ("Push", RTColor.optimal)
        case 65..<80: return ("Solid", RTColor.good)
        case 50..<65: return ("Easy", RTColor.caution)
        default: return ("Rest", RTColor.warning)
        }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                header
                zoneChips
                HStack(spacing: 18) {
                    dial
                    legend
                }
                liveDeltaChip
                caption
            }
            .padding(16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.interactiveRecoveryDialCard)
        .accessibilityLabel("Interactive recovery strain dial")
        .onAppear {
            // Seed angle from current strain/recovery imbalance.
            let rN = baseRecovery / 100
            let sN = baseStrain / 21
            angle = atan2(rN - 0.5, 0.5 - sN) * 180 / .pi
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance Dial")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Text(hasDragged ? "Preview · release to keep exploring" : "Drag the knob to scrub Recovery ↔ Strain")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer()
            Text(zone.label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(zone.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(zone.color.opacity(0.14))
                .clipShape(Capsule())
        }
    }

    private var dial: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.38
            ZStack {
                Circle()
                    .stroke(RTColor.divider, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(previewBalance) / 100)
                    .stroke(zone.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.15), value: previewBalance)
                VStack(spacing: 2) {
                    Text("\(previewBalance)")
                        .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(RTColor.primaryText)
                        .contentTransition(.numericText())
                    Text("BAL")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                }
                Circle()
                    .fill(accent)
                    .frame(width: 18, height: 18)
                    .shadow(color: accent.opacity(0.35), radius: 4, y: 1)
                    .position(
                        x: center.x + CGFloat(cos(angle * .pi / 180)) * radius,
                        y: center.y + CGFloat(sin(angle * .pi / 180)) * radius
                    )
                    .accessibilityIdentifier(SurfaceID.interactiveRecoveryDialKnob)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hasDragged = true
                        let dx = value.location.x - center.x
                        let dy = value.location.y - center.y
                        let next = atan2(dy, dx) * 180 / .pi
                        if abs(next - angle) > 8 { Haptic.selectionChanged() }
                        angle = next
                    }
            )
            .accessibilityIdentifier(SurfaceID.interactiveRecoveryDial)
        }
        .frame(width: 140, height: 140)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 12) {
            legendRow(title: "Recovery", value: "\(previewRecovery)%", color: RTColor.optimal, icon: "heart.fill")
            legendRow(title: "Strain", value: String(format: "%.1f/21", previewStrain), color: RTColor.caution, icon: "flame.fill")
            if hasDragged {
                Button {
                    Haptic.selectionChanged()
                    hasDragged = false
                    let rN = baseRecovery / 100
                    let sN = baseStrain / 21
                    withAnimation(.easeInOut(duration: 0.25)) {
                        angle = atan2(rN - 0.5, 0.5 - sN) * 180 / .pi
                    }
                } label: {
                    Text("Reset")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.interactiveRecoveryDialReset)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendRow(title: String, value: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 22, height: 22)
                .background(color.opacity(0.14))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Text(value)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.primaryText)
                    .contentTransition(.numericText())
            }
        }
    }

    /// Honest #522: snap dial into Rest/Easy/Solid/Push coaching zones.
    private var zoneChips: some View {
        HStack(spacing: 8) {
            ForEach(DialZonePreset.allCases) { preset in
                Button {
                    Haptic.selectionChanged()
                    hasDragged = true
                    withAnimation(.easeInOut(duration: 0.2)) {
                        angle = preset.angle
                    }
                } label: {
                    Text(preset.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(zone.label == preset.title ? Color.white : preset.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(zone.label == preset.title ? preset.color : preset.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Zone \(preset.title)")
            }
        }
        .accessibilityIdentifier(SurfaceID.interactiveRecoveryDialZones)
        .accessibilityLabel("Balance dial zone presets")
    }

    private var liveDeltaChip: some View {
        let live = Int((baseRecovery * 0.65 + (100 - (baseStrain / 21.0) * 100) * 0.35).rounded())
        let d = previewBalance - live
        return HStack(spacing: 8) {
            Text("Live \(live)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(RTColor.secondaryText)
            Image(systemName: "arrow.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(accent)
            Text("Preview \(previewBalance)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(accent)
            Spacer()
            Text(d == 0 ? "±0" : String(format: "%+d BAL", d))
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(d >= 0 ? RTColor.optimal : RTColor.warning)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background((d >= 0 ? RTColor.optimal : RTColor.warning).opacity(0.14))
                .clipShape(Capsule())
        }
        .accessibilityLabel("Preview balance versus live \(d)")
    }

    private var caption: some View {
        Text(hasDragged
             ? "Preview only — Live Balance card above stays on today’s numbers."
             : "Knob maps angle → Recovery / Strain preview for coaching intuition.")
            .font(.caption)
            .foregroundStyle(RTColor.tertiaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}


// MARK: - Zone presets (Honest #522)

enum DialZonePreset: String, CaseIterable, Identifiable {
    case rest, easy, solid, push
    var id: String { rawValue }
    var title: String {
        switch self {
        case .rest: return "Rest"
        case .easy: return "Easy"
        case .solid: return "Solid"
        case .push: return "Push"
        }
    }
    var color: Color {
        switch self {
        case .rest: return RTColor.warning
        case .easy: return RTColor.caution
        case .solid: return RTColor.good
        case .push: return RTColor.optimal
        }
    }
    /// Angle that tends to land the preview in this zone.
    var angle: Double {
        switch self {
        case .rest: return 120
        case .easy: return 40
        case .solid: return -20
        case .push: return -90
        }
    }
}
