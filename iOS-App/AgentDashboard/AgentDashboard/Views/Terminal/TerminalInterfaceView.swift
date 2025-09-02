//
//  TerminalInterfaceView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Complete terminal interface with SwiftTerm integration, history, and filtering
//

import SwiftUI
import ComposableArchitecture

// MARK: - Terminal Interface View

struct TerminalInterfaceView: View {
    let store: StoreOf<TerminalFeature>
    
    @State private var showHistory: Bool = false
    @State private var showFilters: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // Terminal toolbar
                terminalToolbar(viewStore: viewStore)
                
                // Main terminal view
                GeometryReader { geometry in
                    SwiftTermWrapper(
                        store: store,
                        fontSize: viewStore.fontSize,
                        fontFamily: "Menlo",
                        backgroundColor: .systemBackground,
                        foregroundColor: .label
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                // Bottom controls
                bottomControls(viewStore: viewStore)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Terminal")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    terminalActions(viewStore: viewStore)
                }
            }
            .sheet(isPresented: $showHistory) {
                commandHistorySheet(viewStore: viewStore)
            }
            .sheet(isPresented: $showFilters) {
                outputFiltersSheet(viewStore: viewStore)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                handleKeyboardShow(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                handleKeyboardHide()
            }
            .padding(.bottom, keyboardHeight)
            .onAppear {
                print("[TerminalInterfaceView] Terminal interface appeared")
                viewStore.send(.onAppear)
            }
            .onDisappear {
                print("[TerminalInterfaceView] Terminal interface disappeared")
                viewStore.send(.onDisappear)
            }
        }
    }
    
    // MARK: - Terminal Toolbar
    
    private func terminalToolbar(viewStore: ViewStoreOf<TerminalFeature>) -> some View {
        HStack {
            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(viewStore.isExecuting ? .orange : .green)
                    .frame(width: 8, height: 8)
                
                Text(viewStore.isExecuting ? "Executing..." : "Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick actions
            HStack(spacing: 12) {
                Button(action: {
                    showHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                }
                .accessibilityLabel("Show command history")
                
                Button(action: {
                    showFilters = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                }
                .accessibilityLabel("Show output filters")
                
                Button(action: {
                    viewStore.send(.clearOutput)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .accessibilityLabel("Clear terminal output")
            }
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
    
    // MARK: - Bottom Controls
    
    private func bottomControls(viewStore: ViewStoreOf<TerminalFeature>) -> some View {
        VStack(spacing: 0) {
            // Command input area
            HStack(spacing: 12) {
                // Prompt indicator
                Text("AgentDashboard>")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                
                // Command input
                TextField("Enter command", text: viewStore.binding(
                    get: \.currentCommand,
                    send: TerminalFeature.Action.commandTextChanged
                ))
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    if !viewStore.currentCommand.isEmpty {
                        print("[TerminalInterfaceView] Command submitted: \(viewStore.currentCommand)")
                        viewStore.send(.executeCommand)
                    }
                }
                .disabled(viewStore.isExecuting)
                
                // Execute button
                Button(action: {
                    print("[TerminalInterfaceView] Execute button tapped")
                    viewStore.send(.executeCommand)
                }) {
                    Image(systemName: viewStore.isExecuting ? "stop.circle" : "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewStore.isExecuting ? .red : .blue)
                }
                .disabled(viewStore.currentCommand.isEmpty && !viewStore.isExecuting)
                .accessibilityLabel(viewStore.isExecuting ? "Stop command execution" : "Execute command")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            
            // Quick command shortcuts
            if !viewStore.commandHistory.isEmpty {
                quickCommandShortcuts(viewStore: viewStore)
            }
        }
    }
    
    // MARK: - Quick Command Shortcuts
    
    private func quickCommandShortcuts(viewStore: ViewStoreOf<TerminalFeature>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewStore.commandHistory.suffix(5).reversed()), id: \.self) { command in
                    Button(action: {
                        print("[TerminalInterfaceView] Quick command selected: \(command)")
                        viewStore.send(.commandTextChanged(command))
                    }) {
                        Text(command)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 40)
        .background(.regularMaterial.opacity(0.5))
    }
    
    // MARK: - Toolbar Actions
    
    private func terminalActions(viewStore: ViewStoreOf<TerminalFeature>) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                viewStore.send(.toggleTimestamps)
            }) {
                Image(systemName: viewStore.showTimestamps ? "clock.fill" : "clock")
            }
            .accessibilityLabel("Toggle timestamps")
            
            Button(action: {
                viewStore.send(.toggleWrapText)
            }) {
                Image(systemName: viewStore.isWrapText ? "text.wrap" : "text.append")
            }
            .accessibilityLabel("Toggle text wrapping")
        }
    }
    
    // MARK: - Command History Sheet
    
    private func commandHistorySheet(viewStore: ViewStoreOf<TerminalFeature>) -> some View {
        NavigationView {
            List {
                ForEach(Array(viewStore.commandHistory.enumerated().reversed()), id: \.offset) { index, command in
                    Button(action: {
                        print("[TerminalInterfaceView] History command selected: \(command)")
                        viewStore.send(.commandTextChanged(command))
                        showHistory = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(command)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                                
                                Text("Command \(viewStore.commandHistory.count - index)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Copy to clipboard
                                UIPasteboard.general.string = command
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Command History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        showHistory = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewStore.send(.clearHistory)
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Output Filters Sheet
    
    private func outputFiltersSheet(viewStore: ViewStoreOf<TerminalFeature>) -> some View {
        NavigationView {
            Form {
                Section("Text Filter") {
                    TextField("Search output", text: viewStore.binding(
                        get: \.filterText,
                        send: TerminalFeature.Action.filterTextChanged
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                
                Section("Log Level") {
                    Picker("Level", selection: viewStore.binding(
                        get: \.filterLevel,
                        send: TerminalFeature.Action.filterLevelChanged
                    )) {
                        Text("All").tag(TerminalFeature.State.LogLevel?.none)
                        
                        ForEach(TerminalFeature.State.LogLevel.allCases, id: \.rawValue) { level in
                            Text(level.rawValue).tag(level as TerminalFeature.State.LogLevel?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Display Options") {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(viewStore.fontSize))pt")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: viewStore.binding(
                            get: \.fontSize,
                            send: TerminalFeature.Action.fontSizeChanged
                        ),
                        in: 8...24,
                        step: 1
                    )
                    
                    Toggle("Show Timestamps", isOn: viewStore.binding(
                        get: \.showTimestamps,
                        send: { _ in TerminalFeature.Action.toggleTimestamps }
                    ))
                    
                    Toggle("Wrap Text", isOn: viewStore.binding(
                        get: \.isWrapText,
                        send: { _ in TerminalFeature.Action.toggleWrapText }
                    ))
                    
                    Toggle("Auto Scroll", isOn: viewStore.binding(
                        get: \.autoScroll,
                        send: { _ in TerminalFeature.Action.toggleAutoScroll }
                    ))
                }
            }
            .navigationTitle("Terminal Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilters = false
                    }
                }
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func handleKeyboardShow(notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardHeight = keyboardFrame.height
        }
    }
    
    private func handleKeyboardHide() {
        keyboardHeight = 0
    }
}

// MARK: - Preview

#if DEBUG
struct TerminalInterfaceView_Previews: PreviewProvider {
    static var previews: some View {
        TerminalInterfaceView(
            store: Store(initialState: TerminalFeature.State()) {
                TerminalFeature()
            }
        )
        .preferredColorScheme(.dark)
    }
}
#endif