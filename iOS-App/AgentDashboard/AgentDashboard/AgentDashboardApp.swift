import SwiftUI
import ComposableArchitecture
import UIKit

@main
struct AgentDashboardApp: App {
    // Use the comprehensive AppFeature that includes all features
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .onAppear {
                    print("🚀 [AgentDashboardApp] App launched with comprehensive AppFeature")
                    store.send(.applicationDidBecomeActive)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    store.send(.applicationDidBecomeActive)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    store.send(.enterBackground)
                }
        }
    }
}