//
//  TerminalView.swift
//  AgentDashboard
//

import SwiftUI
import ComposableArchitecture

struct TerminalView: View {
    let store: StoreOf<TerminalFeature>
    
    var body: some View {
        // Use the existing TerminalInterfaceView implementation
        TerminalInterfaceView(store: store)
    }
}