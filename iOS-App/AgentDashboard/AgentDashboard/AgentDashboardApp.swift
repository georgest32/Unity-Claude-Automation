import SwiftUI
import ComposableArchitecture

@main
struct AgentDashboardApp: App {
    let store = StoreOf<DashboardFeature>(initialState: .init()) {
        DashboardFeature()
    }

    var body: some Scene {
        WindowGroup {
            DashboardView(store: store)
        }
    }
}