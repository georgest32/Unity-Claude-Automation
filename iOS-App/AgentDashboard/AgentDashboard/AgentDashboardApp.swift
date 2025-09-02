import SwiftUI
import ComposableArchitecture

@main
struct AgentDashboardApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
            ._printChanges()
    } withDependencies: {
        $0.authenticationClient = .liveValue
        $0.webSocketClient = .liveValue
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
                .preferredColorScheme(.dark)
                .onAppear {
                    configureAppearance()
                }
        }
    }
    
    private func configureAppearance() {
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Debug logging
        print("[AgentDashboard] TCA App launched at \(Date())")
        print("[AgentDashboard] iOS Version: \(UIDevice.current.systemVersion)")
        print("[AgentDashboard] Device: \(UIDevice.current.name)")
    }
}