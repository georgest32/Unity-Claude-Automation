//
//  AgentDashboardApp.swift
//  AgentDashboard
//
//  Created on 2025-08-31
//  Unity-Claude-Automation iOS Dashboard
//

import SwiftUI
import ComposableArchitecture

@main
struct AgentDashboardApp: App {
    // Initialize TCA store
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
            ._printChanges()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Self.store)
                .preferredColorScheme(.dark) // Default to dark mode
                .onAppear {
                    configureAppearance()
                }
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Debug logging
        print("[AgentDashboard] App launched at \(Date())")
        print("[AgentDashboard] iOS Version: \(UIDevice.current.systemVersion)")
        print("[AgentDashboard] Device: \(UIDevice.current.name)")
    }
}