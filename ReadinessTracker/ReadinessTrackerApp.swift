import SwiftUI
import BackgroundTasks

@main
struct ReadinessTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Auto-request HealthKit authorization on first launch
        Task {
            await HealthKitManager.shared.requestAuthorization()
            // After auth, fetch historical data from Apple Health (past 30 days)
            await HealthKitManager.shared.fetchHistoricalData(days: 30)
        }
        
        // Register background refresh
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.refreshTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        scheduleAppRefresh()
        
        return true
    }
    
    static let refreshTaskIdentifier = "com.readinesstracker.refresh"
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: AppDelegate.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        let refreshTask = Task {
            await HealthKitManager.shared.fetchTodayData()
        }
        task.expirationHandler = {
            refreshTask.cancel()
            task.setTaskCompleted(success: false)
        }
        Task {
            await refreshTask.value
            task.setTaskCompleted(success: !refreshTask.isCancelled)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == "readinesstracker" {
            FitbitManager.shared.handleCallback(url: url)
        }
        return true
    }
}
