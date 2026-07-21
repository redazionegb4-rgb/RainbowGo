import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Esplora", systemImage: "sparkles") }

            FavoritesPlaceholderView()
                .tabItem { Label("Preferiti", systemImage: "heart.fill") }

            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
        }
        .tint(.white)
    }
}

private struct FavoritesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ContentUnavailableView("Nessun preferito", systemImage: "heart", description: Text("I preferiti saranno disponibili nella prossima build."))
                    .foregroundStyle(.white)
            }
            .navigationTitle("Preferiti")
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("RainbowGo") {
                    Label("Ricerca automatica con Apple Maps", systemImage: "map.fill")
                    Label("Nessun account richiesto", systemImage: "person.crop.circle.badge.checkmark")
                    Label("Versione 0.1", systemImage: "hammer.fill")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Impostazioni")
        }
    }
}
