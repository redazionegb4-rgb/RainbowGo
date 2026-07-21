import SwiftUI
import MapKit

struct MapView: View {
    let places: [Place]
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                UserAnnotation()
                ForEach(places) { place in
                    Marker(place.name, systemImage: place.category.symbol, coordinate: place.coordinate)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .navigationTitle("Mappa LGBTQ+")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .onAppear {
                if let coordinate = userLocation?.coordinate {
                    position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 20_000, longitudinalMeters: 20_000))
                }
            }
        }
    }
}
