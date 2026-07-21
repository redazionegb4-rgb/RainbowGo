import SwiftUI
import MapKit
import CoreLocation

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesService()
    @AppStorage("searchRadiusKm") private var searchRadiusKm = 15.0

    @State private var selectedCategory: PlaceCategory = .all
    @State private var selectedCityName = ""
    @State private var selectedLocation: CLLocation?
    @State private var usesCurrentLocation = true
    @State private var showMap = false
    @State private var showCityPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                background
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        topBar
                        cityHero
                        categories
                        resultHeader
                        results
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
                .refreshable { await reload() }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { locationManager.requestAccess() }
        .onChange(of: locationManager.location) { _, location in
            guard usesCurrentLocation, let location else { return }
            selectedLocation = location
            selectedCityName = locationManager.cityName
            Task { await reload() }
        }
        .onChange(of: locationManager.cityName) { _, city in
            guard usesCurrentLocation, city != "Posizione attuale", let location = locationManager.location else { return }
            selectedCityName = city
            selectedLocation = location
            Task { await reload() }
        }
        .onChange(of: selectedCategory) { _, _ in Task { await reload() } }
        .onChange(of: searchRadiusKm) { _, _ in Task { await reload() } }
        .sheet(isPresented: $showMap) {
            MapView(places: placesService.places, centerLocation: selectedLocation, cityName: displayedCity)
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerSheet(currentCity: locationManager.cityName, currentLocation: locationManager.location) { choice in
                usesCurrentLocation = choice.usesCurrentLocation
                selectedCityName = choice.name
                selectedLocation = choice.location
                showCityPicker = false
                Task { await reload() }
            }
            .presentationDetents([.large])
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.035, green: 0.04, blue: 0.075).ignoresSafeArea()
            Circle()
                .fill(Color.purple.opacity(0.26))
                .frame(width: 330, height: 330)
                .blur(radius: 90)
                .offset(x: 150, y: -300)
            Circle()
                .fill(Color.blue.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: -170, y: 280)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 43, height: 43)

                VStack(alignment: .leading, spacing: 1) {
                    Text("RAINBOWGO")
                        .font(.caption.weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.55))
                    Text("Scopri. Vivi. Connettiti.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            Button { showMap = true } label: {
                Image(systemName: "map.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.09), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.10)))
            }
            .disabled(placesService.places.isEmpty)
        }
    }

    private var cityHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("ESPLORA LA CITTÀ")
                        .font(.caption2.weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.68))
                    Text(displayedCity)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(usesCurrentLocation ? "Rilevata automaticamente" : "Città scelta manualmente")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Image(systemName: usesCurrentLocation ? "location.fill" : "building.2.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            }

            Button { showCityPicker = true } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Scegli o cerca un'altra città")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.14)))
            }
        }
        .padding(21)
        .background(
            LinearGradient(
                colors: [Color(red: 0.88, green: 0.18, blue: 0.48), Color(red: 0.44, green: 0.20, blue: 0.90), Color(red: 0.10, green: 0.45, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 29)
        )
        .shadow(color: .purple.opacity(0.22), radius: 22, y: 12)
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cosa cerchi?")
                .font(.title3.bold())
                .foregroundStyle(.white)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PlaceCategory.allCases) { category in
                        Button { selectedCategory = category } label: {
                            VStack(spacing: 8) {
                                Image(systemName: category.symbol)
                                    .font(.system(size: 19, weight: .semibold))
                                Text(category.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(selectedCategory == category ? .black : .white)
                            .frame(width: 76, height: 72)
                            .background(selectedCategory == category ? Color.white : Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(selectedCategory == category ? 0 : 0.10)))
                        }
                    }
                }
            }
        }
    }

    private var resultHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Posti a \(displayedCity)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Solo risultati appartenenti alla città")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
            }
            Spacer()
            Text("\(placesService.places.count)")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.white.opacity(0.09), in: Capsule())
        }
    }

    @ViewBuilder
    private var results: some View {
        if selectedLocation == nil || displayedCity == "Posizione attuale" {
            statusCard(icon: "location.circle", title: "Cerco la tua città", message: "Consenti l'accesso alla posizione oppure scegli una città manualmente.")
        } else if placesService.isLoading {
            VStack(spacing: 14) {
                ProgressView().tint(.white).scaleEffect(1.15)
                Text("Ricerca in corso a \(displayedCity)…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 52)
        } else if let message = placesService.errorMessage ?? locationManager.errorMessage {
            statusCard(icon: "mappin.slash.fill", title: "Nessun posto trovato", message: message)
        } else {
            LazyVStack(spacing: 13) {
                ForEach(placesService.places) { place in PlaceCard(place: place) }
            }
        }
    }

    private func statusCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 31, weight: .semibold))
                .foregroundStyle(.white)
            Text(title).font(.headline).foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08)))
    }

    private var displayedCity: String {
        selectedCityName.isEmpty ? locationManager.cityName : selectedCityName
    }

    private func reload() async {
        guard let selectedLocation, !displayedCity.isEmpty, displayedCity != "Posizione attuale" else { return }
        await placesService.search(around: selectedLocation, cityName: displayedCity, category: selectedCategory, radiusKm: searchRadiusKm)
    }
}

private struct CityChoice {
    let name: String
    let location: CLLocation
    let usesCurrentLocation: Bool
}

private struct CitySearchResult: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let location: CLLocation
}

private struct CityPickerSheet: View {
    let currentCity: String
    let currentLocation: CLLocation?
    let onSelect: (CityChoice) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [CitySearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.035, green: 0.04, blue: 0.075).ignoresSafeArea()
                VStack(spacing: 16) {
                    HStack(spacing: 11) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.55))
                        TextField("Cerca città, es. Madrid", text: $query)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                            .submitLabel(.search)
                            .onSubmit { Task { await search() } }
                        if !query.isEmpty {
                            Button { query = ""; results = [] } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.45))
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 52)
                    .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 17))
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.09)))

                    Button {
                        guard let location = currentLocation else { return }
                        onSelect(CityChoice(name: currentCity, location: location, usesCurrentLocation: true))
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Usa posizione attuale").font(.headline)
                                Text(currentCity).font(.subheadline).foregroundStyle(.white.opacity(0.55))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.white.opacity(0.45))
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 21))
                    }
                    .disabled(currentCity == "Posizione attuale")

                    if isSearching {
                        Spacer()
                        ProgressView("Cerco la città…").tint(.white).foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    } else if let errorMessage {
                        Spacer()
                        ContentUnavailableView("Città non trovata", systemImage: "building.2.crop.circle", description: Text(errorMessage))
                            .foregroundStyle(.white)
                        Spacer()
                    } else if results.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "globe.europe.africa.fill").font(.system(size: 43)).foregroundStyle(.white.opacity(0.75))
                            Text("Cerca qualsiasi città").font(.title3.bold()).foregroundStyle(.white)
                            Text("L'app mostrerà esclusivamente i luoghi della città selezionata.")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.55)).multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 35)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(results) { result in
                                    Button {
                                        onSelect(CityChoice(name: result.name, location: result.location, usesCurrentLocation: false))
                                    } label: {
                                        HStack(spacing: 13) {
                                            Image(systemName: "building.2.fill")
                                                .foregroundStyle(.white)
                                                .frame(width: 42, height: 42)
                                                .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(result.name).font(.headline)
                                                Text(result.subtitle).font(.caption).foregroundStyle(.white.opacity(0.52)).lineLimit(1)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.white.opacity(0.4))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(14)
                                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .navigationTitle("Scegli città")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Chiudi") { dismiss() }.foregroundStyle(.white) }
            }
        }
    }

    private func search() async {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 2 else { return }
        isSearching = true
        errorMessage = nil
        results = []
        defer { isSearching = false }

        do {
            let placemarks = try await geocoder.geocodeAddressString(value)
            var seen = Set<String>()
            results = placemarks.compactMap { mark in
                guard let location = mark.location else { return nil }
                let city = mark.locality ?? mark.subAdministrativeArea ?? mark.administrativeArea ?? value
                let country = mark.country ?? ""
                let key = "\(city)-\(country)".lowercased()
                guard seen.insert(key).inserted else { return nil }
                let subtitle = [mark.administrativeArea, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                return CitySearchResult(name: city, subtitle: subtitle, location: location)
            }
            if results.isEmpty { errorMessage = "Prova a inserire anche la nazione." }
        } catch {
            errorMessage = "Controlla il nome e riprova."
        }
    }
}
