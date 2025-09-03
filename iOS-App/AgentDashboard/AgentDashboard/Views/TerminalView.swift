//
//  TerminalView.swift
//  AgentDashboard
//

import SwiftUI
import ComposableArchitecture

struct TerminalView: View {
    let store: StoreOf<TerminalFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationView {
                VStack(spacing: 0) {
                    // Output area
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(store.output.enumerated()), id: \.offset) { _, line in
                                    TerminalOutputLine(line: line)
                                }
                                
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(Color.black)
                        .onChange(of: store.output.count) { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Input area
                    HStack(spacing: 8) {
                        Text(">")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                        
                        TextField("Enter command", text: .init(
                            get: { store.currentInput },
                            set: { store.send(.inputChanged($0)) }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.plain)
                        .onSubmit {
                            store.send(.executeCommand)
                        }
                        
                        Button {
                            store.send(.executeCommand)
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .disabled(store.currentInput.isEmpty)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.05))
                }
                .navigationTitle("Terminal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            store.send(.clearOutput)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

struct TerminalOutputLine: View {
    let line: TerminalFeature.OutputLine
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if line.type != .output {
                Text(line.type.prefix)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(line.type.color)
            }
            
            Text(line.text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(line.type == .error ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}