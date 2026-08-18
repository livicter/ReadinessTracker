import SwiftUI

/// Daily coaching feed: ranked insight cards, highest-impact first.
/// Each card explains why a metric moved vs the user's own baselines
/// and gives one concrete action. Self-contained — drop into any tab
/// or push as a navigation destination.
struct CoachingView: View {
    let source: DataSource
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var metadataStore = MetadataStore.shared

    init(source: DataSource = .appleWatch) {
        self.source = source
    }

    private var feed: [CoachingInsight] {
        AIRecommendationEngine.shared.generateCoachingFeed(for: source)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppleTheme.sectionSpacing) {
                        if feed.isEmpty {
                            emptyState
                        } else {
                            ForEach(feed) { insight in
                                CoachingCard(insight: insight)
                            }
                        }
                    }
                    .padding(.horizontal, AppleTheme.horizontalMargin)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    Haptic.press()
                    dataStore.load()
                }
            }
            .navigationTitle("Coaching")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RTColor.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 48))
                .foregroundStyle(RTColor.surfaceHighlight)

            Text("No coaching insights yet")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Sync a few days of health data and the coaching feed will explain your trends and suggest actions.")
                .font(.subheadline)
                .foregroundStyle(RTColor.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Coaching Card

private struct CoachingCard: View {
    let insight: CoachingInsight

    private var tint: Color {
        switch insight.category {
        case .sleep: return RTColor.sleep
        case .hrv: return RTColor.hrv
        case .restingHR: return RTColor.recovery
        case .strain: return RTColor.strain
        case .nutrition: return RTColor.caution
        case .behavior: return RTColor.consistency
        case .stress: return RTColor.warning
        case .training: return RTColor.optimal
        }
    }

    private var impactLabel: (text: String, color: Color) {
        switch insight.impact {
        case 70...100: return ("High impact", RTColor.warning)
        case 40..<70: return ("Medium impact", RTColor.caution)
        default: return ("Good to know", RTColor.optimal)
        }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: insight.category.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint)
                        .frame(width: 36, height: 36)
                        .background(tint.opacity(0.12))
                        .clipShape(Circle())

                    Text(insight.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Text(impactLabel.text)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(impactLabel.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(impactLabel.color.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(insight.explanation)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.optimal)

                    Text(insight.action)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                        .fill(RTColor.surfaceHighlight)
                )
            }
        }
    }
}

#Preview {
    CoachingView()
}
