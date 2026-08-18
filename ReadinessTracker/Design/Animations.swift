import SwiftUI

// MARK: - Animated Number (Count Up)
struct AnimatedNumber: View {
    let value: Int
    let font: Font
    let color: Color
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .onAppear {
                // Only animate on first appear, not on re-appear
                if displayValue == 0 {
                    animateCount()
                }
            }
    }
    
    private func animateCount() {
        guard value > 0 else {
            displayValue = value
            return
        }
        let duration: Double = 0.8
        let steps = min(value, 60)
        let interval = duration / Double(steps)
        
        displayValue = 0
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                displayValue = Int(Double(value) * min(1.0, Double(i) / Double(steps)))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            displayValue = value
        }
    }
}

// MARK: - Animated Ring
struct AnimatedRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: animatedProgress)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: size, height: size)
            .onAppear {
                // Only animate on first appear
                if animatedProgress == 0 {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animatedProgress = progress
                    }
                }
            }
    }
}

// MARK: - Card Expand Animation
struct ExpandableCard<Content: View>: View {
    @State private var isExpanded: Bool = false
    let content: Content
    let expandedContent: Content
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder expanded: () -> Content) {
        self.content = content()
        self.expandedContent = expanded()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isExpanded.toggle()
                    }
                }
            
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .background(RTColor.surface)
        .cornerRadius(RTLayout.cardCornerRadius)
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + phase * geo.size.width * 2)
                }
                .mask(content)
            )
            .onAppear {
                // Prevent re-triggering shimmer
                if phase == 0 {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Pulse Effect
struct PulseModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(color)
                    .scaleEffect(scale)
                    .opacity(opacity)
            )
            .onAppear {
                // Prevent re-triggering pulse
                if scale == 1.0 {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        scale = 1.3
                        opacity = 0
                    }
                }
            }
    }
}

extension View {
    func pulse(color: Color) -> some View {
        modifier(PulseModifier(color: color))
    }
}

// MARK: - Slide In Animation (DEPRECATED - causes flickering)
// Use explicit .animation(value:) instead of this modifier
struct SlideInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible: Bool = false
    @State private var hasAnimated: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                // Only animate once
                if !hasAnimated {
                    hasAnimated = true
                    withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                        isVisible = true
                    }
                } else {
                    isVisible = true
                }
            }
    }
}

extension View {
    func slideIn(delay: Double = 0) -> some View {
        modifier(SlideInModifier(delay: delay))
    }
}

// MARK: - Animated Progress Bar
struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(RTColor.surfaceHighlight)
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: max(4, geo.size.width * animatedProgress), height: height)
                    .shadow(color: color.opacity(0.4), radius: 3)
            }
        }
        .frame(height: height)
        .onAppear {
            // Only animate on first appear
            if animatedProgress == 0 {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animatedProgress = progress
                }
            }
        }
    }
}

// MARK: - Animated Sparkline (Line Draw)
struct AnimatedSparkline: View {
    let data: [Double]
    let color: Color
    @State private var trimEnd: CGFloat = 0
    
    private var normalized: [Double] {
        guard let min = data.min(), let max = data.max(), max > min else { return data }
        return data.map { ($0 - min) / (max - min) }
    }
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let stepX = width / CGFloat(max(1, normalized.count - 1))
            
            Path { path in
                for (i, val) in normalized.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = height - (CGFloat(val) * height)
                    let point = CGPoint(x: x, y: y)
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            .trim(from: 0, to: trimEnd)
            .stroke(color.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .onAppear {
            // Only animate on first appear
            if trimEnd == 0 {
                withAnimation(.easeOut(duration: 1.0)) {
                    trimEnd = 1
                }
            }
        }
    }
}

// MARK: - Bounce Button
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Refresh Spinner
struct RefreshSpinner: View {
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(RTColor.secondaryText)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { 
                // Prevent re-triggering
                if !isAnimating {
                    isAnimating = true 
                }
            }
    }
}
