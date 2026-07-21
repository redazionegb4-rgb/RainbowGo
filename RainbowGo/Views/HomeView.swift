import SwiftUI
import MapKit

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesService()
    @State private var selectedCategory: PlaceCategory = .all
    @State private var showMap = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.06, blue: 0.20), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    hero
                    categories
                    resultsHeader
                    content
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .task {
            locationManager.requestAccess()
        }
        .onChange(of: locationManager.location) { _, newValue in
            guard let newValue else { return }
            Task { await placesService.search(around: newValue, category: selectedCategory) }
        }
        .onChange(of: selectedCategory) { _, newValue in
            guard let location = locationManager.location else { return }
            Task { await placesService.search(around: location, category: newValue) }
        }
        .sheet(isPresented: $showMap) {
            MapView(places: placesService.places, userLocation: locationManager.location)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("RAINBOWGO")
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.7))
                Label(locationManager.cityName, systemImage: "location.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {
                locationManager.refresh()
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, 10)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scopri il tuo mondo\nLGBTQ+ vicino a te")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Locali, community e luoghi trovati automaticamente nella città in cui ti trovi.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))

            Button {
                showMap = true
            } label: {
                Label("Apri la mappa", systemImage: "map.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [.pink.opacity(0.85), .purple.opacity(0.85), .blue.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var categories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PlaceCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category.rawValue, systemImage: category.symbol)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(selectedCategory == category ? .white : .white.opacity(0.08))
                            .foregroundStyle(selectedCategory == category ? .black : .white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var resultsHeader: some View {
        HStack {
            Text("Luoghi trovati")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Spacer()
            Text("\(placesService.places.count)")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private var content: some View {
        if placesService.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("Cerco i posti migliori…")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
        } else if let message = locationManager.errorMessage ?? placesService.errorMessage {
            ContentUnavailableView("Nessun risultato", systemImage: "mappin.slash", description: Text(message))
                .foregroundStyle(.white)
        } else {
            LazyVStack(spacing: 14) {
                ForEach(placesService.places) { place in
                    PlaceCard(place: place)
                }
            }
        }
    }
}
