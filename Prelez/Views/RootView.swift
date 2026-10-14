import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case session, routes, stats, search
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selection: AppTab = .session

    var body: some View {
        TabView(selection: $selection) {
            Tab("Trénink", systemImage: "figure.climbing", value: AppTab.session) {
                SessionView()
            }
            Tab("Cesty", systemImage: "list.bullet.rectangle", value: AppTab.routes) {
                RoutesView()
            }
            Tab("Statistiky", systemImage: "chart.bar.xaxis", value: AppTab.stats) {
                StatsView()
            }
            Tab("Hledat", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SearchRoutesView()
            }
        }
        #if os(iOS)
        // Liquid Glass tab bar: shrinks while scrolling, the running session sits above it like a mini player.
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            SessionAccessory()
        }
        #endif
        #if DEBUG
        .task {
            if let tab = DemoData.initialTab { selection = tab }
            do {
                try DemoData.seedIfRequested(context)
            } catch {
                print("Demo data failed: \(error)")
            }
        }
        #endif
    }
}

#Preview {
    RootView()
        .modelContainer(try! AppModelContainer.inMemory())
}
