import SwiftUI

struct ContentView: View {
    @AppStorage("appearance") private var appearance = "dark"

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Scopri", systemImage: "location.magnifyingglass") }

            AppInfoView()
                .tabItem { Label("Guida", systemImage: "book.pages.fill") }

            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "slider.horizontal.3") }
        }
        .tint(.purple)
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

private struct AppInfoView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.035, green: 0.04, blue: 0.075).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 9) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 34, weight: .bold))
                            Text("Come funziona")
                                .font(.largeTitle.bold())
                            Text("RainbowGo cerca automaticamente luoghi LGBTQ+ tramite Apple Maps. Non è necessario inserire manualmente locali o città.")
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .foregroundStyle(.white)
                        .padding(22)
                        .background(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28))

                        guideRow(icon: "location.fill", title: "Posizione automatica", text: "All'avvio viene rilevata la città in cui ti trovi.")
                        guideRow(icon: "building.2.fill", title: "Scegli una città", text: "Puoi cercare qualsiasi altra città dalla Home.")
                        guideRow(icon: "checkmark.shield.fill", title: "Solo risultati della città", text: "I luoghi esterni alla città selezionata vengono esclusi.")
                        guideRow(icon: "map.fill", title: "Mappa e indicazioni", text: "Apri la mappa o avvia subito il percorso con Apple Maps.")
                    }
                    .padding(18)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Guida")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func guideRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 45, height: 45)
                .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(text).font(.subheadline).foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(.white.opacity(0.07)))
    }
}

private struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "dark"
    @AppStorage("searchRadiusKm") private var searchRadiusKm = 15.0
    @AppStorage("distanceUnit") private var distanceUnit = "metric"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.035, green: 0.04, blue: 0.075).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        settingSection("Aspetto") {
                            Picker("Tema", selection: $appearance) {
                                Text("Sistema").tag("system")
                                Text("Chiaro").tag("light")
                                Text("Scuro").tag("dark")
                            }
                            .pickerStyle(.segmented)
                        }

                        settingSection("Ricerca") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("Raggio massimo", systemImage: "scope")
                                    Spacer()
                                    Text("\(Int(searchRadiusKm)) km").foregroundStyle(.secondary)
                                }
                                Slider(value: $searchRadiusKm, in: 5...30, step: 5)
                            }
                            Divider().overlay(.white.opacity(0.08))
                            Picker("Distanze", selection: $distanceUnit) {
                                Text("Chilometri").tag("metric")
                                Text("Miglia").tag("imperial")
                            }
                        }

                        settingSection("Privacy") {
                            Label("La posizione viene usata solo sul dispositivo", systemImage: "hand.raised.fill")
                            Divider().overlay(.white.opacity(0.08))
                            Label("Nessun account richiesto", systemImage: "person.crop.circle.badge.checkmark")
                            Divider().overlay(.white.opacity(0.08))
                            Label("Nessun database personale", systemImage: "externaldrive.badge.xmark")
                        }

                        settingSection("Informazioni") {
                            HStack { Text("Applicazione"); Spacer(); Text("RainbowGo").foregroundStyle(.secondary) }
                            Divider().overlay(.white.opacity(0.08))
                            HStack { Text("Versione"); Spacer(); Text("0.2 (3)").foregroundStyle(.secondary) }
                            Divider().overlay(.white.opacity(0.08))
                            Label("Dati dei luoghi forniti da Apple Maps", systemImage: "apple.logo")
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Impostazioni")
        }
    }

    private func settingSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.45))
            VStack(alignment: .leading, spacing: 13) { content() }
                .foregroundStyle(.white)
                .padding(16)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 21))
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(.white.opacity(0.075)))
        }
    }
}
