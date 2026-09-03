import SwiftUI

struct BreathingView: View {
    @State private var isBreathing = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var circleScale: CGFloat = 1.0
    @State private var elapsedTime: TimeInterval = 0
    @State private var breathCount = 0
    @State private var hrvReading: Double? = nil
    @State private var showHRV = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let breathCycle: TimeInterval = 10 // 4-7-8 breathing: 4 inhale, 7 hold, 8 exhale
    private let totalDuration: TimeInterval = 300 // 5 minutes
    
    enum BreathPhase: String {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"
        
        var duration: TimeInterval {
            switch self {
            case .inhale: return 4
            case .hold: return 2
            case .exhale: return 4
            }
        }
        
        var color: Color {
            switch self {
            case .inhale: return RTColor.hrv
            case .hold: return RTColor.sleep
            case .exhale: return RTColor.optimal
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Text("HRV Coherence")
                        .font(RTFont.title)
                        .foregroundColor(.white)
                    
                    Text("Breathe to improve your heart rate variability")
                        .font(RTFont.body)
                        .foregroundColor(RTColor.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Breathing circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(breathPhase.color.opacity(0.1))
                        .frame(width: 280, height: 280)
                        .scaleEffect(circleScale)
                    
                    // Main circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [breathPhase.color.opacity(0.3), breathPhase.color.opacity(0.1)],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(circleScale)
                        .overlay(
                            Circle()
                                .stroke(breathPhase.color.opacity(0.5), lineWidth: 2)
                        )
                    
                    // Phase text
                    VStack(spacing: 8) {
                        Text(breathPhase.rawValue)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if isBreathing {
                            Text("\(Int(breathPhase.duration - (elapsedTime.truncatingRemainder(dividingBy: breathPhase.duration))))s")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(breathPhase.color)
                        }
                    }
                }
                
                // Stats
                HStack(spacing: 30) {
                    BreathingStatItem(label: "Breaths", value: "\(breathCount)")
                    BreathingStatItem(label: "Time", value: formatTime(elapsedTime))
                    if let hrv = hrvReading {
                        BreathingStatItem(label: "HRV", value: String(format: "%.0f", hrv))
                    }
                }
                
                Spacer()
                
                // Control button
                AppButton(
                    title: isBreathing ? "Stop" : "Start",
                    systemImage: isBreathing ? "stop.fill" : "play.fill",
                    color: isBreathing ? RTColor.warning : RTColor.optimal,
                    action: toggleBreathing
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Simulate HRV reading after session
            if showHRV {
                hrvReading = Double.random(in: 45...65)
            }
        }
    }
    
    private func toggleBreathing() {
        // Haptic.press() fires from AppButton
        isBreathing.toggle()
        
        if isBreathing {
            startBreathingCycle()
        }
    }
    
    private func startBreathingCycle() {
        guard isBreathing else { return }
        
        // Animate through phases (skip circle motion when Reduce Motion is on)
        if reduceMotion {
            circleScale = 1.0
        } else {
            withAnimation(.easeInOut(duration: breathPhase.duration)) {
                switch breathPhase {
                case .inhale:
                    circleScale = 1.3
                case .hold:
                    circleScale = 1.3
                case .exhale:
                    circleScale = 1.0
                }
            }
        }
        
        // Schedule next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + breathPhase.duration) {
            guard isBreathing else { return }
            
            // Advance phase
            switch breathPhase {
            case .inhale:
                breathPhase = .hold
            case .hold:
                breathPhase = .exhale
            case .exhale:
                breathPhase = .inhale
                breathCount += 1
            }
            
            // Gentle phase-change cue so users can follow with eyes closed
            Haptic.soft()
            
            elapsedTime += breathPhase.duration
            
            // Auto-stop after 5 minutes
            if elapsedTime >= totalDuration {
                isBreathing = false
                showHRV = true
                hrvReading = Double.random(in: 50...70) // Simulated post-session HRV
            } else {
                startBreathingCycle()
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct BreathingStatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(RTColor.secondaryText)
        }
    }
}
