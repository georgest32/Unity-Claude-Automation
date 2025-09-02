import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Agent Dashboard")
                    .font(.title)
                    .padding()
                Text("Unity-Claude-Automation iOS App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}