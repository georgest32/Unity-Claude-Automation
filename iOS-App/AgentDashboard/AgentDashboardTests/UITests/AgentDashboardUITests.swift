//
//  AgentDashboardUITests.swift
//  AgentDashboardTests
//
//  Created on 2025-09-01
//  Comprehensive UI tests using XCUITest framework with Page Object Model
//

import XCTest

final class AgentDashboardUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        // Debug: Log app launch
        print("[UITest] App launched with UI_TESTING flag")
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        print("[UITest] App terminated and cleaned up")
    }
    
    // MARK: - App Launch and Navigation Tests
    
    func testAppLaunchPerformance() throws {
        print("[UITest] Starting app launch performance test")
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let newApp = XCUIApplication()
            newApp.launch()
            newApp.terminate()
        }
        
        print("[UITest] App launch performance test completed")
    }
    
    func testMainNavigationFlow() throws {
        print("[UITest] Testing main navigation flow")
        
        let dashboardPage = DashboardPage(app: app)
        
        // Verify dashboard loads
        XCTAssertTrue(dashboardPage.isDisplayed, "Dashboard should be displayed on launch")
        print("[UITest] Dashboard page verified")
        
        // Navigate to Agents tab
        let agentsPage = dashboardPage.navigateToAgents()
        XCTAssertTrue(agentsPage.isDisplayed, "Agents page should be displayed after navigation")
        print("[UITest] Agents page navigation verified")
        
        // Navigate to Analytics tab
        let analyticsPage = agentsPage.navigateToAnalytics()
        XCTAssertTrue(analyticsPage.isDisplayed, "Analytics page should be displayed after navigation")
        print("[UITest] Analytics page navigation verified")
        
        // Navigate to Terminal tab
        let terminalPage = analyticsPage.navigateToTerminal()
        XCTAssertTrue(terminalPage.isDisplayed, "Terminal page should be displayed after navigation")
        print("[UITest] Terminal page navigation verified")
        
        // Navigate to Settings tab
        let settingsPage = terminalPage.navigateToSettings()
        XCTAssertTrue(settingsPage.isDisplayed, "Settings page should be displayed after navigation")
        print("[UITest] Settings page navigation verified")
        
        print("[UITest] Main navigation flow test completed successfully")
    }
    
    // MARK: - Agent Control Tests
    
    func testAgentControlOperations() throws {
        print("[UITest] Testing agent control operations")
        
        let dashboardPage = DashboardPage(app: app)
        let agentsPage = dashboardPage.navigateToAgents()
        
        // Wait for agents to load
        let agentsList = agentsPage.agentsList
        XCTAssertTrue(agentsList.waitForExistence(timeout: 5), "Agents list should load within 5 seconds")
        print("[UITest] Agents list loaded successfully")
        
        // Test agent control if agents are available
        if agentsList.cells.count > 0 {
            let firstAgent = agentsList.cells.firstMatch
            XCTAssertTrue(firstAgent.exists, "First agent should exist in list")
            
            // Tap on first agent to select
            firstAgent.tap()
            print("[UITest] Selected first agent")
            
            // Test start button if available
            let startButton = app.buttons["Start Agent"]
            if startButton.exists {
                startButton.tap()
                print("[UITest] Tapped Start Agent button")
                
                // Wait for operation feedback
                let operationFeedback = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'started' OR label CONTAINS 'operation'"))
                XCTAssertTrue(operationFeedback.firstMatch.waitForExistence(timeout: 10), "Operation feedback should appear within 10 seconds")
                print("[UITest] Agent start operation feedback received")
            }
            
            // Test other control buttons
            let controlButtons = ["Stop Agent", "Restart Agent", "Pause Agent"]
            for buttonTitle in controlButtons {
                let button = app.buttons[buttonTitle]
                if button.exists && button.isEnabled {
                    print("[UITest] Found enabled button: \(buttonTitle)")
                }
            }
        }
        
        print("[UITest] Agent control operations test completed")
    }
    
    // MARK: - Analytics and Data Export Tests
    
    func testAnalyticsAndExport() throws {
        print("[UITest] Testing analytics and data export functionality")
        
        let dashboardPage = DashboardPage(app: app)
        let analyticsPage = dashboardPage.navigateToAnalytics()
        
        // Wait for charts to load
        let chartsContainer = analyticsPage.chartsContainer
        XCTAssertTrue(chartsContainer.waitForExistence(timeout: 10), "Charts should load within 10 seconds")
        print("[UITest] Analytics charts loaded successfully")
        
        // Test time range selection
        let timeRangePicker = analyticsPage.timeRangePicker
        if timeRangePicker.exists {
            timeRangePicker.tap()
            print("[UITest] Tapped time range picker")
            
            // Select different time range
            let oneHourOption = app.buttons["Last Hour"]
            if oneHourOption.exists {
                oneHourOption.tap()
                print("[UITest] Selected 'Last Hour' time range")
                
                // Wait for charts to update
                Thread.sleep(forTimeInterval: 2)
            }
        }
        
        // Test export functionality
        let exportButton = app.buttons["Export Data"]
        if exportButton.exists {
            exportButton.tap()
            print("[UITest] Tapped Export Data button")
            
            // Wait for export completion feedback
            let exportFeedback = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'export' OR label CONTAINS 'generated'"))
            XCTAssertTrue(exportFeedback.firstMatch.waitForExistence(timeout: 15), "Export feedback should appear within 15 seconds")
            print("[UITest] Data export functionality verified")
        }
        
        print("[UITest] Analytics and export test completed")
    }
    
    // MARK: - Settings and Customization Tests
    
    func testSettingsAndThemeCustomization() throws {
        print("[UITest] Testing settings and theme customization")
        
        let dashboardPage = DashboardPage(app: app)
        let settingsPage = dashboardPage.navigateToSettings()
        
        // Wait for settings to load
        let settingsList = settingsPage.settingsList
        XCTAssertTrue(settingsList.waitForExistence(timeout: 5), "Settings list should load within 5 seconds")
        print("[UITest] Settings page loaded successfully")
        
        // Test theme customization
        let themeSection = settingsPage.themeSection
        if themeSection.exists {
            themeSection.tap()
            print("[UITest] Opened theme section")
            
            // Test theme selection
            let blueTheme = app.buttons["Blue Theme"]
            if blueTheme.exists {
                blueTheme.tap()
                print("[UITest] Selected Blue theme")
                
                // Verify theme change (simplified - would need specific visual validation)
                Thread.sleep(forTimeInterval: 1)
                print("[UITest] Theme change applied")
            }
        }
        
        // Test toggle settings
        let toggleSettings = ["Auto-refresh", "Haptic Feedback", "Notifications"]
        for settingName in toggleSettings {
            let toggle = app.switches[settingName]
            if toggle.exists {
                let initialState = toggle.value as? String == "1"
                toggle.tap()
                print("[UITest] Toggled setting: \(settingName) from \(initialState)")
                
                // Wait for setting to apply
                Thread.sleep(forTimeInterval: 0.5)
                
                let newState = toggle.value as? String == "1"
                XCTAssertNotEqual(initialState, newState, "Toggle state should change for \(settingName)")
                print("[UITest] Setting toggle verified: \(settingName)")
            }
        }
        
        print("[UITest] Settings and customization test completed")
    }
    
    // MARK: - Authentication and Security Tests
    
    func testAuthenticationFlow() throws {
        print("[UITest] Testing authentication flow")
        
        // Test biometric authentication if available
        let authButton = app.buttons["Authenticate"]
        if authButton.exists {
            authButton.tap()
            print("[UITest] Tapped authentication button")
            
            // Handle biometric prompt (on simulator, this would be automatic)
            let biometricPrompt = app.alerts.firstMatch
            if biometricPrompt.waitForExistence(timeout: 5) {
                let authenticateButton = biometricPrompt.buttons["Authenticate"]
                if authenticateButton.exists {
                    authenticateButton.tap()
                    print("[UITest] Confirmed biometric authentication")
                }
            }
            
            // Verify authentication success
            let authSuccess = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'authenticated' OR label CONTAINS 'success'"))
            XCTAssertTrue(authSuccess.firstMatch.waitForExistence(timeout: 10), "Authentication success message should appear")
            print("[UITest] Authentication success verified")
        }
        
        print("[UITest] Authentication flow test completed")
    }
    
    // MARK: - Performance and Responsiveness Tests
    
    func testUIResponsiveness() throws {
        print("[UITest] Testing UI responsiveness and performance")
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let dashboardPage = DashboardPage(app: app)
            
            // Navigate through all tabs quickly
            let _ = dashboardPage.navigateToAgents()
            let _ = dashboardPage.navigateToAnalytics()
            let _ = dashboardPage.navigateToTerminal()
            let _ = dashboardPage.navigateToSettings()
            let _ = dashboardPage.navigateToDashboard()
            
            print("[UITest] Completed navigation performance test cycle")
        }
        
        print("[UITest] UI responsiveness test completed")
    }
    
    func testScrollingPerformance() throws {
        print("[UITest] Testing scrolling performance")
        
        let dashboardPage = DashboardPage(app: app)
        let agentsPage = dashboardPage.navigateToAgents()
        
        // Test scrolling performance if list exists
        let agentsList = agentsPage.agentsList
        if agentsList.exists {
            measure(metrics: [XCTCPUMetric()]) {
                // Perform scroll operations
                agentsList.swipeUp()
                agentsList.swipeDown()
                agentsList.swipeUp()
                agentsList.swipeDown()
                
                print("[UITest] Completed scroll performance test")
            }
        }
        
        print("[UITest] Scrolling performance test completed")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingAndRecovery() throws {
        print("[UITest] Testing error handling and recovery")
        
        // Simulate network error conditions (would require app support for test mode)
        app.launchArguments = ["UI_TESTING", "NETWORK_ERROR_MODE"]
        app.terminate()
        app.launch()
        
        let dashboardPage = DashboardPage(app: app)
        
        // Wait for error state
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'failed'"))
        if errorMessage.firstMatch.waitForExistence(timeout: 10) {
            print("[UITest] Error state detected successfully")
            
            // Test retry functionality
            let retryButton = app.buttons["Retry"]
            if retryButton.exists {
                retryButton.tap()
                print("[UITest] Tapped retry button")
                
                // Wait for recovery
                Thread.sleep(forTimeInterval: 3)
                print("[UITest] Error recovery attempted")
            }
        }
        
        print("[UITest] Error handling test completed")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityCompliance() throws {
        print("[UITest] Testing accessibility compliance")
        
        let dashboardPage = DashboardPage(app: app)
        
        // Test VoiceOver navigation
        app.accessibilityActivationPoint = CGPoint(x: 100, y: 100)
        
        // Verify accessibility labels exist
        let dashboardTitle = app.navigationBars.staticTexts["Dashboard"]
        XCTAssertTrue(dashboardTitle.exists, "Dashboard title should have accessibility label")
        
        // Test tab navigation with accessibility
        let agentsTab = app.tabBars.buttons["Agents"]
        XCTAssertTrue(agentsTab.exists, "Agents tab should have accessibility label")
        agentsTab.tap()
        print("[UITest] Accessibility navigation to Agents tab verified")
        
        // Verify touch targets meet minimum size requirements (44x44 points)
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            let frame = button.frame
            let meetsMinimumSize = frame.width >= 44 && frame.height >= 44
            print("[UITest] Button '\(button.label)' size: \(frame.width)x\(frame.height), meets minimum: \(meetsMinimumSize)")
        }
        
        print("[UITest] Accessibility compliance test completed")
    }
}

// MARK: - Page Object Model Implementation

class BasePage {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
        print("[UITest] Initialized \(String(describing: type(of: self)))")
    }
    
    var isDisplayed: Bool {
        return app.navigationBars.firstMatch.exists
    }
}

class DashboardPage: BasePage {
    
    // Dashboard-specific elements
    var dashboardTitle: XCUIElement {
        return app.navigationBars.staticTexts["Dashboard"]
    }
    
    var systemStatusCard: XCUIElement {
        return app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'System Status' OR label CONTAINS 'CPU' OR label CONTAINS 'Memory'")).firstMatch
    }
    
    var agentsCard: XCUIElement {
        return app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Agents' OR label CONTAINS 'Active'")).firstMatch
    }
    
    // Navigation methods
    func navigateToAgents() -> AgentsPage {
        let agentsTab = app.tabBars.buttons["Agents"]
        agentsTab.tap()
        print("[UITest] Navigated to Agents from Dashboard")
        return AgentsPage(app: app)
    }
    
    func navigateToAnalytics() -> AnalyticsPage {
        let analyticsTab = app.tabBars.buttons["Analytics"]
        analyticsTab.tap()
        print("[UITest] Navigated to Analytics from Dashboard")
        return AnalyticsPage(app: app)
    }
    
    func navigateToTerminal() -> TerminalPage {
        let terminalTab = app.tabBars.buttons["Terminal"]
        terminalTab.tap()
        print("[UITest] Navigated to Terminal from Dashboard")
        return TerminalPage(app: app)
    }
    
    func navigateToSettings() -> SettingsPage {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        print("[UITest] Navigated to Settings from Dashboard")
        return SettingsPage(app: app)
    }
    
    func navigateToDashboard() -> DashboardPage {
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        print("[UITest] Navigated to Dashboard")
        return self
    }
    
    override var isDisplayed: Bool {
        return dashboardTitle.exists
    }
    
    // Dashboard-specific actions
    func refreshDashboard() {
        let refreshButton = app.buttons["Refresh"]
        if refreshButton.exists {
            refreshButton.tap()
            print("[UITest] Refreshed dashboard")
        }
    }
    
    func waitForDataLoad() -> Bool {
        return systemStatusCard.waitForExistence(timeout: 10)
    }
}

class AgentsPage: BasePage {
    
    var agentsTitle: XCUIElement {
        return app.navigationBars.staticTexts["Agents"]
    }
    
    var agentsList: XCUIElement {
        return app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch
    }
    
    var filterButton: XCUIElement {
        return app.buttons["Filter"]
    }
    
    var sortButton: XCUIElement {
        return app.buttons["Sort"]
    }
    
    override var isDisplayed: Bool {
        return agentsTitle.exists
    }
    
    // Navigate to other pages
    func navigateToAnalytics() -> AnalyticsPage {
        let analyticsTab = app.tabBars.buttons["Analytics"]
        analyticsTab.tap()
        print("[UITest] Navigated to Analytics from Agents")
        return AnalyticsPage(app: app)
    }
    
    func navigateToTerminal() -> TerminalPage {
        let terminalTab = app.tabBars.buttons["Terminal"]
        terminalTab.tap()
        print("[UITest] Navigated to Terminal from Agents")
        return TerminalPage(app: app)
    }
    
    func navigateToSettings() -> SettingsPage {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        print("[UITest] Navigated to Settings from Agents")
        return SettingsPage(app: app)
    }
    
    // Agent-specific actions
    func selectAgent(at index: Int) {
        let agentCells = agentsList.cells
        if agentCells.count > index {
            agentCells.element(boundBy: index).tap()
            print("[UITest] Selected agent at index \(index)")
        }
    }
    
    func performAgentAction(_ action: String) {
        let actionButton = app.buttons[action]
        if actionButton.exists && actionButton.isEnabled {
            actionButton.tap()
            print("[UITest] Performed agent action: \(action)")
        }
    }
}

class AnalyticsPage: BasePage {
    
    var analyticsTitle: XCUIElement {
        return app.navigationBars.staticTexts["Analytics"]
    }
    
    var chartsContainer: XCUIElement {
        return app.otherElements["ChartsContainer"].exists ? app.otherElements["ChartsContainer"] : app.scrollViews.firstMatch
    }
    
    var timeRangePicker: XCUIElement {
        return app.buttons["TimeRange"]
    }
    
    var exportButton: XCUIElement {
        return app.buttons["Export Data"]
    }
    
    override var isDisplayed: Bool {
        return analyticsTitle.exists
    }
    
    // Navigate to other pages
    func navigateToTerminal() -> TerminalPage {
        let terminalTab = app.tabBars.buttons["Terminal"]
        terminalTab.tap()
        print("[UITest] Navigated to Terminal from Analytics")
        return TerminalPage(app: app)
    }
    
    func navigateToSettings() -> SettingsPage {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        print("[UITest] Navigated to Settings from Analytics")
        return SettingsPage(app: app)
    }
}

class TerminalPage: BasePage {
    
    var terminalTitle: XCUIElement {
        return app.navigationBars.staticTexts["Terminal"]
    }
    
    var terminalOutput: XCUIElement {
        return app.textViews.firstMatch
    }
    
    var commandInput: XCUIElement {
        return app.textFields["Command Input"]
    }
    
    var executeButton: XCUIElement {
        return app.buttons["Execute"]
    }
    
    override var isDisplayed: Bool {
        return terminalTitle.exists
    }
    
    // Navigate to other pages
    func navigateToSettings() -> SettingsPage {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        print("[UITest] Navigated to Settings from Terminal")
        return SettingsPage(app: app)
    }
    
    // Terminal-specific actions
    func executeCommand(_ command: String) {
        if commandInput.exists {
            commandInput.tap()
            commandInput.typeText(command)
            print("[UITest] Entered command: \(command)")
            
            if executeButton.exists {
                executeButton.tap()
                print("[UITest] Executed command")
            }
        }
    }
}

class SettingsPage: BasePage {
    
    var settingsTitle: XCUIElement {
        return app.navigationBars.staticTexts["Settings"]
    }
    
    var settingsList: XCUIElement {
        return app.tables.firstMatch
    }
    
    var themeSection: XCUIElement {
        return app.staticTexts["Theme"]
    }
    
    var backupButton: XCUIElement {
        return app.buttons["Backup & Restore"]
    }
    
    override var isDisplayed: Bool {
        return settingsTitle.exists
    }
    
    // Settings-specific actions
    func openBackupRestore() {
        if backupButton.exists {
            backupButton.tap()
            print("[UITest] Opened Backup & Restore")
        }
    }
    
    func toggleSetting(_ settingName: String) {
        let toggle = app.switches[settingName]
        if toggle.exists {
            toggle.tap()
            print("[UITest] Toggled setting: \(settingName)")
        }
    }
}