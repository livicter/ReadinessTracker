import SwiftUI

/// Sync status indicator showing last sync time and data freshness.
/// Appears below the source picker on the dashboard.
struct SyncStatusView: View {
    let lastSync: Date?
    let isSyncing: Bool
    let sourceName: String
    let onSync: () -> Void
    
    @State private var pulse = false
    
    var body: some View {
        NativeCard {
            HStack(spacing: 8) {
            // Status dot with pulse animation when syncing
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                if isSyncing {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulse ? 2.0 : 1.0)
                        .opacity(pulse ? 0.0 : 0.6)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }
                }
            }
            
            // Status text
            Text(statusText)
                .font(.caption2.weight(.medium))
                .foregroundStyle(statusColor)
            
            Spacer()
            
            // Sync button
            Button(action: onSync) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .rotationEffect(.degrees(isSyncing ? 360 : 0))
                        .animation(isSyncing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: isSyncing)
                    Text(isSyncing ? "Syncing..." : "Sync")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(isSyncing ? RTColor.optimal : RTColor.secondaryText)
            }
            .buttonStyle(.plain)
            .disabled(isSyncing)
            }
        }
    }
    
    private var statusColor: Color {
        if isSyncing { return RTColor.optimal }
        guard let lastSync = lastSync else { return RTColor.warning }
        let hoursSince = Date().timeIntervalSince(lastSync) / 3600
        if hoursSince < 1 { return RTColor.optimal }
        if hoursSince < 6 { return RTColor.caution }
        return RTColor.warning
    }
    
    private var statusText: String {
        if isSyncing { return "Syncing \(sourceName)..." }
        guard let lastSync = lastSync else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Updated \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
    }
}

/// A subtle animated transition for content state changes.
/// Fades and slides content in when data becomes available.
struct ContentStateTransition<Content: View>: View {
    let isLoaded: Bool
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .opacity(isLoaded ? 1 : 0)
            .offset(y: isLoaded ? 0 : 8)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLoaded)
    }
}

/// Animated number that counts up when the value changes.
/// Used for readiness scores and metric values.
struct AnimatedMetricValue: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .onAppear {
                animateTo(value)
            }
            .onChange(of: value) { newValue in
                animateTo(newValue)
            }
    }
    
    private func animateTo(_ target: Int) {
        let duration = 0.6
        let steps = 20
        let stepDuration = duration / Double(steps)
        let increment = Double(target - displayValue) / Double(steps)
        
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                displayValue = displayValue + Int(increment)
                if step == steps {
                    displayValue = target
                }
            }
        }
    }
}
