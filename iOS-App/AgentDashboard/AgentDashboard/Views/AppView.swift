import SwiftUI
import ComposableArchitecture

/// Main app view using TCA (The Composable Architecture)
struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            Group {
                if store.isAuthenticated {
                    MainTabView(store: store)
                } else {
                    AuthenticationView(store: store)
                }
            }
            .onAppear {
                store.send(.applicationDidBecomeActive)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                store.send(.applicationDidEnterBackground)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                store.send(.applicationDidBecomeActive)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
                // Dashboard Tab
                DashboardView(
                    store: store.scope(state: \.dashboard, action: \.dashboard)
                )
                .tabItem {
                    Image(systemName: AppFeature.State.Tab.dashboard.iconName)
                    Text(AppFeature.State.Tab.dashboard.rawValue)
                }
                .tag(AppFeature.State.Tab.dashboard)
                
                // Agents Tab
                AgentsView(
                    store: store.scope(state: \.agents, action: \.agents)
                )
                .tabItem {
                    Image(systemName: AppFeature.State.Tab.agents.iconName)
                    Text(AppFeature.State.Tab.agents.rawValue)
                }
                .tag(AppFeature.State.Tab.agents)
                
                // Terminal Tab
                TerminalView(
                    store: store.scope(state: \.terminal, action: \.terminal)
                )
                .tabItem {
                    Image(systemName: AppFeature.State.Tab.terminal.iconName)
                    Text(AppFeature.State.Tab.terminal.rawValue)
                }
                .tag(AppFeature.State.Tab.terminal)
                
                // Analytics Tab
                AnalyticsView(
                    store: store.scope(state: \.analytics, action: \.analytics)
                )
                .tabItem {
                    Image(systemName: AppFeature.State.Tab.analytics.iconName)
                    Text(AppFeature.State.Tab.analytics.rawValue)
                }
                .tag(AppFeature.State.Tab.analytics)
                
                // Settings Tab
                SettingsView(
                    store: store.scope(state: \.settings, action: \.settings)
                )
                .tabItem {
                    Image(systemName: AppFeature.State.Tab.settings.iconName)
                    Text(AppFeature.State.Tab.settings.rawValue)
                }
                .tag(AppFeature.State.Tab.settings)
            }
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.checkerboard")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Unity-Claude-Automation")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Agent Dashboard")
                .font(.title2)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Text("Please authenticate to access the dashboard")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button {
                    store.send(.authenticateUser)
                } label: {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Authenticate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Placeholder Views removed - using real implementations from separate files

// MARK: - Preview

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}