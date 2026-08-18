import SwiftUI

/// Root: vertical pager (swipe or Digital Crown) over the three glanceable pages.
struct ContentView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        NavigationStack {
            TabView {
                WatchDashboardView()
                WatchStrainView()
                WatchSleepView()
            }
            .tabViewStyle(.verticalPage)
        }
        .onAppear {
            session.requestSnapshot()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSessionManager.shared)
}
