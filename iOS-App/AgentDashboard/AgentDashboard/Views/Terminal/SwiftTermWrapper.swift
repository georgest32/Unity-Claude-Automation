//
//  SwiftTermWrapper.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  SwiftUI wrapper for SwiftTerm using UIViewRepresentable with TerminalViewDelegate
//

import SwiftUI
import SwiftTerm
import ComposableArchitecture

// MARK: - SwiftTerm SwiftUI Wrapper

struct SwiftTermWrapper: UIViewRepresentable {
    
    // TCA store connection
    let store: StoreOf<TerminalFeature>
    
    // Terminal configuration
    let fontSize: Double
    let fontFamily: String
    let backgroundColor: UIColor
    let foregroundColor: UIColor
    
    init(store: StoreOf<TerminalFeature>,
         fontSize: Double = 13.0,
         fontFamily: String = "Menlo",
         backgroundColor: UIColor = .systemBackground,
         foregroundColor: UIColor = .label) {
        
        self.store = store
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        
        print("[SwiftTermWrapper] Initialized with font: \(fontFamily) \(fontSize)pt")
    }
    
    func makeUIView(context: Context) -> SwiftTermView {
        print("[SwiftTermWrapper] Creating SwiftTerm view")
        
        let terminalView = SwiftTermView(store: store)
        terminalView.configureAppearance(
            fontSize: fontSize,
            fontFamily: fontFamily,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )
        
        // Connect to TCA store
        context.coordinator.connectToStore(store)
        
        return terminalView
    }
    
    func updateUIView(_ uiView: SwiftTermView, context: Context) {
        // Update terminal configuration based on TCA state
        let viewStore = ViewStore(store, observe: { $0 })
        
        print("[SwiftTermWrapper] Updating terminal view with state changes")
        
        // Update font size if changed
        if viewStore.fontSize != fontSize {
            uiView.updateFontSize(viewStore.fontSize)
        }
        
        // Update text wrapping
        uiView.updateTextWrapping(viewStore.isWrapText)
        
        // Feed new output lines to terminal
        context.coordinator.updateTerminalOutput(uiView, state: viewStore.state)
    }
    
    func makeCoordinator() -> Coordinator {
        print("[SwiftTermWrapper] Creating coordinator")
        return Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        private var store: StoreOf<TerminalFeature>?
        private var lastOutputCount: Int = 0
        
        func connectToStore(_ store: StoreOf<TerminalFeature>) {
            self.store = store
            print("[SwiftTermWrapper.Coordinator] Connected to TCA store")
        }
        
        func updateTerminalOutput(_ terminalView: SwiftTermView, state: TerminalFeature.State) {
            // Only process new output lines to avoid duplicates
            let newOutputCount = state.outputLines.count
            
            if newOutputCount > lastOutputCount {
                let newLines = Array(state.outputLines.suffix(newOutputCount - lastOutputCount))
                
                for line in newLines {
                    let output = formatOutputLine(line, showTimestamps: state.showTimestamps)
                    terminalView.feedText(output)
                    
                    print("[SwiftTermWrapper.Coordinator] Fed line to terminal: \(line.content.prefix(50))...")
                }
                
                lastOutputCount = newOutputCount
                
                // Auto-scroll if enabled
                if state.autoScroll {
                    terminalView.scrollToBottom()
                }
            }
        }
        
        private func formatOutputLine(_ line: TerminalFeature.TerminalLine, showTimestamps: Bool) -> String {
            var output = ""
            
            if showTimestamps {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                output += "[\(formatter.string(from: line.timestamp))] "
            }
            
            // Add log level indicator
            switch line.level {
            case .error:
                output += "❌ "
            case .warning:
                output += "⚠️ "
            case .info:
                output += "ℹ️ "
            case .debug:
                output += "🔍 "
            }
            
            output += line.content + "\n"
            return output
        }
    }
}

// MARK: - SwiftTerm View Implementation

class SwiftTermView: TerminalView, TerminalViewDelegate {
    
    private var terminalStore: StoreOf<TerminalFeature>?
    private var currentCommand: String = ""
    
    init(store: StoreOf<TerminalFeature>) {
        super.init(frame: .zero)
        
        self.terminalStore = store
        self.terminalViewDelegate = self
        
        print("[SwiftTermView] Initialized with TCA store connection")
        
        setupTerminal()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupTerminal() {
        print("[SwiftTermView] Setting up terminal configuration")
        
        // Configure terminal properties
        self.allowsSelection = true
        self.isAccessibilityElement = true
        self.accessibilityLabel = "Terminal"
        self.accessibilityHint = "Interactive terminal for command execution"
        
        // Add welcome message
        DispatchQueue.main.async {
            self.feedText("Unity-Claude-Automation Terminal\n")
            self.feedText("Type commands to execute on remote system\n")
            self.feedText("AgentDashboard> ")
        }
    }
    
    func configureAppearance(fontSize: Double, fontFamily: String, backgroundColor: UIColor, foregroundColor: UIColor) {
        print("[SwiftTermView] Configuring appearance: \(fontFamily) \(fontSize)pt")
        
        // Configure terminal colors and fonts
        self.backgroundColor = backgroundColor
        
        // Set terminal colors (SwiftTerm specific configuration)
        var colors = Colors()
        colors.foreground = foregroundColor
        colors.background = backgroundColor
        self.colors = colors
        
        // Font configuration
        if let font = UIFont(name: fontFamily, size: fontSize) {
            self.font = font
        } else {
            self.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }
    
    func updateFontSize(_ newSize: Double) {
        print("[SwiftTermView] Updating font size to: \(newSize)pt")
        
        if let currentFont = self.font {
            self.font = currentFont.withSize(newSize)
        }
    }
    
    func updateTextWrapping(_ enabled: Bool) {
        print("[SwiftTermView] Text wrapping: \(enabled)")
        // SwiftTerm handles text wrapping automatically based on terminal width
    }
    
    func feedText(_ text: String) {
        print("[SwiftTermView] Feeding text to terminal: \(text.prefix(50))...")
        
        if let data = text.data(using: .utf8) {
            self.feed(byteArray: Array(data))
        }
    }
    
    func scrollToBottom() {
        DispatchQueue.main.async {
            let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height + self.contentInset.bottom)
            if bottomOffset.y > 0 {
                self.setContentOffset(bottomOffset, animated: true)
            }
        }
    }
    
    // MARK: - TerminalViewDelegate Implementation
    
    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        print("[SwiftTermView] Sending data: \(data.count) bytes")
        
        // Convert bytes to string
        guard let command = String(bytes: data, encoding: .utf8) else {
            print("[SwiftTermView] Failed to convert command data to string")
            return
        }
        
        // Handle command processing
        processCommand(command)
    }
    
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        print("[SwiftTermView] Terminal size changed: \(newCols)x\(newRows)")
        
        // Notify TCA store of size change
        if let store = terminalStore {
            store.send(.terminalResized(cols: newCols, rows: newRows))
        }
    }
    
    func setTerminalTitle(source: TerminalView, title: String) {
        print("[SwiftTermView] Terminal title set: \(title)")
        
        // Could update navigation title or store in TCA state
        if let store = terminalStore {
            store.send(.terminalTitleChanged(title))
        }
    }
    
    func clipboardCopy(source: TerminalView, content: Data) {
        print("[SwiftTermView] Clipboard copy: \(content.count) bytes")
        
        if let text = String(data: content, encoding: .utf8) {
            UIPasteboard.general.string = text
            
            // Show feedback
            feedText("\n[Copied to clipboard]\n")
        }
    }
    
    // MARK: - Command Processing
    
    private func processCommand(_ command: String) {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("[SwiftTermView] Processing command: \(trimmedCommand)")
        
        // Handle special terminal commands
        if trimmedCommand == "clear" {
            clearTerminal()
            return
        }
        
        if trimmedCommand.isEmpty {
            showPrompt()
            return
        }
        
        // Send command to TCA store for execution
        if let store = terminalStore {
            // Update current command in state
            store.send(.commandTextChanged(trimmedCommand))
            
            // Execute command
            store.send(.executeCommand)
        }
    }
    
    private func clearTerminal() {
        print("[SwiftTermView] Clearing terminal")
        
        // Clear terminal display
        self.clearBuffer()
        
        // Send clear action to TCA store
        if let store = terminalStore {
            store.send(.clearOutput)
        }
        
        // Show fresh prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showPrompt()
        }
    }
    
    private func showPrompt() {
        feedText("AgentDashboard> ")
    }
    
    // MARK: - Terminal Control Methods
    
    func executeCommandProgrammatically(_ command: String) {
        print("[SwiftTermView] Executing programmatic command: \(command)")
        
        feedText("\(command)\n")
        processCommand(command)
    }
    
    func insertTextAtCursor(_ text: String) {
        print("[SwiftTermView] Inserting text at cursor: \(text)")
        
        feedText(text)
    }
}

// MARK: - Terminal Integration Complete
// TerminalFeature.Action extensions now implemented in TerminalFeature.swift

// MARK: - Preview

#if DEBUG
struct SwiftTermWrapper_Previews: PreviewProvider {
    static var previews: some View {
        SwiftTermWrapper(
            store: Store(initialState: TerminalFeature.State()) {
                TerminalFeature()
            }
        )
        .frame(height: 300)
        .padding()
        .preferredColorScheme(.dark)
    }
}
#endif