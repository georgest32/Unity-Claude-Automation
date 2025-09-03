//
//  AnalyticsView.swift
//  AgentDashboard
//

import SwiftUI
import ComposableArchitecture

struct AnalyticsView: View {
    let store: StoreOf<AnalyticsFeature>
    
    var body: some View {
        // Use the enhanced analytics view implementation
        EnhancedAnalyticsView(store: store)
    }
}