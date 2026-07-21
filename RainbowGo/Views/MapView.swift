import SwiftUI
import MapKit

struct MapView: View {
    let places: [Place]
    let centerLocation: CLLocation?
    let cityName: String
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(places) { place in
                    Marker(place.name, systemImage: place.category.symbol, coordinate: place.coordinate)
                        .tint(.purple)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls { MapCompass(); MapScaleView() }
            .navigationTitle(cityName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Chiudi") { dismiss() } } }
            .onAppear {
                if let coordinate = centerLocation?.coordinate {
                    position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 18_000, longitudinalMeters: 18_000))
                }
            }
        }
    }
}
