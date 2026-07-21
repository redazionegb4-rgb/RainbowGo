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
    @State private var showCityPicker = false
    @State private var showMap = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    cityHero
                    categoryGrid
                    resultsHeader
                    results
                }
                .padding(.horizontal, 17)
                .padding(.bottom, 30)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("RainbowGo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showMap = true } label: {
                        Image(systemName: "map.fill")
                    }
                    .disabled(placesService.places.isEmpty)
                }
            }
            .task {
                locationManager.requestAccess()
            }
            .onChange(of: locationManager.location) { _, value in
                guard usesCurrentLocation, let value else { return }
                selectedLocation = value
                selectedCityName = locationManager.cityName
                Task { await reload() }
            }
            .onChange(of: locationManager.cityName) { _, value in
                guard usesCurrentLocation, value != "Posizione attuale" else { return }
                selectedCityName = value
                Task { await reload() }
            }
            .onChange(of: selectedCategory) { _, _ in
                Task { await reload() }
            }
            .onChange(of: searchRadiusKm) { _, _ in
                Task { await reload() }
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerSheet(currentCity: locationManager.cityName, currentLocation: locationManager.location) { choice in
                    selectedCityName = choice.name
                    selectedLocation = choice.location
                    usesCurrentLocation = choice.usesCurrentLocation
                    showCityPicker = false
                    Task { await reload() }
                }
            }
            .sheet(isPresented: $showMap) {
                MapView(places: placesService.places, centerLocation: selectedLocation, cityName: displayedCity)
            }
            .refreshable { await reload() }
        }
    }

    private var cityHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("STAI ESPLORANDO")
                        .font(.caption2.bold())
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(displayedCity)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Label(usesCurrentLocation ? "Posizione attuale" : "Città scelta", systemImage: usesCurrentLocation ? "location.fill" : "building.2.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.76))
                }
                Spacer()
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 19))
            }

            Button { showCityPicker = true } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Cambia città")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 15)
                .frame(height: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(21)
        .background(
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.11, blue: 0.48), Color(red: 0.55, green: 0.12, blue: 0.58), Color(red: 0.93, green: 0.20, blue: 0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 29)
        )
        .shadow(color: .purple.opacity(0.18), radius: 20, y: 10)
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categorie LGBTQ+")
                .font(.title3.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 11)], spacing: 11) {
                ForEach(PlaceCategory.allCases) { category in
                    Button { selectedCategory = category } label: {
                        VStack(spacing: 9) {
                            Image(systemName: category.symbol)
                                .font(.system(size: 21, weight: .semibold))
                            Text(category.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 78)
                        .background(
                            selectedCategory == category ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)),
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var resultsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Luoghi verificati")
                    .font(.title3.bold())
                Text("Solo risultati con riferimenti LGBTQ+ espliciti")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(placesService.places.count)")
                .font(.subheadline.bold())
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
                .foregroundStyle(Color.accentColor)
        }
    }

    @ViewBuilder
    private var results: some View {
        if selectedLocation == nil || displayedCity == "Posizione attuale" {
            statusCard("location.circle.fill", "Serve una città", "Consenti la posizione oppure scegli manualmente una città.")
        } else if placesService.isLoading {
            VStack(spacing: 13) {
                ProgressView().controlSize(.large)
                Text("Cerco luoghi LGBTQ+ a \(displayedCity)…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
        } else if let message = placesService.errorMessage ?? locationManager.errorMessage {
            statusCard("mappin.slash.fill", "Nessun risultato verificato", message)
        } else {
            LazyVStack(spacing: 13) {
                ForEach(placesService.places) { place in
                    PlaceCard(place: place)
                }
            }
        }
    }

    private func statusCard(_ icon: String, _ title: String, _ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 31, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(27)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }

    private var displayedCity: String {
        selectedCityName.isEmpty ? locationManager.cityName : selectedCityName
    }

    private func reload() async {
        guard let selectedLocation,
              !displayedCity.isEmpty,
              displayedCity != "Posizione attuale" else { return }
        await placesService.search(
            around: selectedLocation,
            cityName: displayedCity,
            category: selectedCategory,
            radiusKm: searchRadiusKm
        )
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
            List {
                Section {
                    Button {
                        guard let currentLocation else { return }
                        onSelect(CityChoice(name: currentCity, location: currentLocation, usesCurrentLocation: true))
                    } label: {
                        Label("Usa la posizione attuale", systemImage: "location.fill")
                    }
                    .disabled(currentLocation == nil || currentCity == "Posizione attuale")
                }

                if isSearching {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.secondary)
                }

                Section("Risultati") {
                    ForEach(results) { result in
                        Button {
                            onSelect(CityChoice(name: result.name, location: result.location, usesCurrentLocation: false))
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(result.name).font(.headline).foregroundStyle(.primary)
                                Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Cerca una città")
            .onSubmit(of: .search) { Task { await search() } }
            .navigationTitle("Scegli città")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        isSearching = true
        errorMessage = nil
        results = []
        defer { isSearching = false }

        do {
            let marks = try await geocoder.geocodeAddressString(trimmed)
            results = marks.prefix(8).compactMap { mark in
                guard let location = mark.location else { return nil }
                let city = mark.locality ?? mark.subAdministrativeArea ?? mark.administrativeArea ?? trimmed
                let subtitle = [mark.administrativeArea, mark.country]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                return CitySearchResult(name: city, subtitle: subtitle, location: location)
            }
            if results.isEmpty { errorMessage = "Nessuna città trovata." }
        } catch {
            errorMessage = "Non riesco a trovare questa città. Controlla il nome e riprova."
        }
    }
}
