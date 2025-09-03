import SwiftUI
import ComposableArchitecture

@main
struct AgentDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView(
                store: Store(
                    initialState: DashboardFeature.State(),
                    reducer: { DashboardFeature() }
                )
            )
        }
    }
}