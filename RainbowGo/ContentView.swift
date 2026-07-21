import SwiftUI

struct ContentView: View {
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Esplora", systemImage: "safari.fill") }

            DiscoverInfoView()
                .tabItem { Label("Come funziona", systemImage: "checkmark.shield.fill") }

            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
        }
        .tint(Color.accentColor)
        .preferredColorScheme(selectedScheme)
    }

    private var selectedScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

private struct DiscoverInfoView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 34, weight: .bold))
                        Text("Solo luoghi LGBTQ+")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("RainbowGo mostra solo risultati che contengono un riferimento LGBTQ+ esplicito nel nome, nel sito o nell'indirizzo. I locali generici vengono esclusi.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))

                    infoRow("location.fill", "Città precisa", "Puoi usare la posizione attuale oppure scegliere manualmente una città.")
                    infoRow("line.3.horizontal.decrease.circle.fill", "Filtro rigoroso", "Meglio pochi risultati affidabili che molti locali non pertinenti.")
                    infoRow("map.fill", "Apple Maps", "Indirizzi, siti e indicazioni vengono aperti direttamente nelle mappe.")
                }
                .padding(18)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Come funziona")
        }
    }

    private func infoRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 46, height: 46)
                .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(17)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("searchRadiusKm") private var searchRadiusKm = 15.0
    @AppStorage("distanceUnit") private var distanceUnit = "metric"
    @AppStorage("showVerification") private var showVerification = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Aspetto", selection: $appearance) {
                        Label("Automatico", systemImage: "circle.lefthalf.filled").tag("system")
                        Label("Chiaro", systemImage: "sun.max.fill").tag("light")
                        Label("Scuro", systemImage: "moon.fill").tag("dark")
                    }
                } header: { Text("Tema") } footer: {
                    Text("Automatico segue l'aspetto impostato su iPhone.")
                }

                Section("Ricerca") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Raggio massimo", systemImage: "scope")
                            Spacer()
                            Text("\(Int(searchRadiusKm)) km").foregroundStyle(.secondary)
                        }
                        Slider(value: $searchRadiusKm, in: 5...30, step: 5)
                    }
                    Picker("Unità distanza", selection: $distanceUnit) {
                        Text("Chilometri").tag("metric")
                        Text("Miglia").tag("imperial")
                    }
                    Toggle("Mostra verifica LGBTQ+", isOn: $showVerification)
                }

                Section("Dati e privacy") {
                    Label("Nessun account richiesto", systemImage: "person.crop.circle.badge.checkmark")
                    Label("Posizione usata solo per la ricerca", systemImage: "location.shield.fill")
                    Label("Nessun elenco inserito manualmente", systemImage: "arrow.triangle.2.circlepath")
                }

                Section("Applicazione") {
                    LabeledContent("Nome", value: "RainbowGo")
                    LabeledContent("Versione", value: "0.3")
                    LabeledContent("Build", value: "4")
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}
