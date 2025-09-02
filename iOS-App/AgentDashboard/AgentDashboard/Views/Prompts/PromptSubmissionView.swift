//
//  PromptSubmissionView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  AI prompt submission interface with multi-line editor and system selection
//

import SwiftUI
import ComposableArchitecture

// MARK: - Prompt Submission View

struct PromptSubmissionView: View {
    let store: StoreOf<PromptFeature>
    
    @FocusState private var isPromptFocused: Bool
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // System selection
                        systemSelectionSection(viewStore: viewStore)
                        
                        // Prompt input
                        promptInputSection(viewStore: viewStore)
                        
                        // Enhancement options
                        enhancementOptionsSection(viewStore: viewStore)
                        
                        // Templates and suggestions
                        templatesSection(viewStore: viewStore)
                        
                        // Submission controls
                        submissionSection(viewStore: viewStore)
                    }
                    .padding()
                }
                .navigationTitle("AI Prompt Submission")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            viewStore.send(.clearPrompt)
                        }
                        .disabled(viewStore.currentPrompt.isEmpty)
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
    
    // MARK: - System Selection Section
    
    private func systemSelectionSection(viewStore: ViewStoreOf<PromptFeature>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target AI System")
                .font(.headline)
                .fontWeight(.semibold)
            
            // AI System picker
            Picker("AI System", selection: viewStore.binding(
                get: \.selectedAISystem,
                send: PromptFeature.Action.aiSystemChanged
            )) {
                ForEach(PromptFeature.State.AISystem.allCases, id: \.rawValue) { system in
                    HStack {
                        Image(systemName: system.icon)
                        Text(system.rawValue)
                    }
                    .tag(system)
                }
            }
            .pickerStyle(.segmented)
            
            // Mode selection (if supported)
            if viewStore.selectedAISystem.supportsModes {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Execution Mode")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Mode", selection: viewStore.binding(
                        get: \.selectedMode,
                        send: PromptFeature.Action.aiModeChanged
                    )) {
                        ForEach(PromptFeature.State.AIMode.allCases, id: \.rawValue) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(viewStore.selectedMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // System status
            HStack {
                Text("Status:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(viewStore.systemStatus.color))
                        .frame(width: 8, height: 8)
                    
                    Text(viewStore.systemStatus.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}