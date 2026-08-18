import SwiftUI

/// Whoop-style balance wheel showing strain vs recovery relationship
struct StrainRecoveryWheel: View {
    let strainScore: Double  // 0-21 scale like Whoop
    let recoveryScore: Double // 0-100%
    let day: String // "DAY 1"
    
    private var recoveryAngle: Double {
        recoveryScore * 3.6 // Convert % to degrees (0-360)
    }
    
    private var strainAngle: Double {
        strainScore * 17.14 // Convert 0-21 to 0-360
    }
    
    var ringThickness: CGFloat = 22
    
    var body: some View {
        VStack(spacing: 12) {
            // Main wheel
            ZStack {
                // Background track
                Circle()
                    .stroke(RTColor.surfaceHighlight, style: StrokeStyle(lineWidth: ringThickness, lineCap: .round))
                
                // Recovery arc (green)
                ArcShape(startAngle: .degrees(-90), endAngle: .degrees(-90 + recoveryAngle))
                    .stroke(RTColor.optimal, style: StrokeStyle(lineWidth: ringThickness, lineCap: .round))
                
                // Strain arc (orange)
                ArcShape(startAngle: .degrees(-90 + recoveryAngle),
                         endAngle: .degrees(-90 + recoveryAngle + min(strainAngle, 360 - recoveryAngle)))
                    .stroke(RTColor.caution, style: StrokeStyle(lineWidth: ringThickness, lineCap: .round))
                
                // Center metrics
                VStack(spacing: 4) {
                    Text(day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(RTColor.secondaryText)
                    
                    Text("\(Int(recoveryScore))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 180, height: 180)
            .padding(ringThickness/2)
            
            // Legend
            HStack(spacing: 20) {
                SRLegendItem(color: RTColor.optimal, label: "Recovery")
                SRLegendItem(color: RTColor.caution, label: "Strain")
            }
        }
    }
}

private struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: min(rect.width, rect.height)/2,
                 startAngle: startAngle,
                 endAngle: endAngle,
                 clockwise: false)
        return p
    }
}

private struct SRLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(RTColor.secondaryText)
        }
    }
}