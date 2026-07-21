import Foundation
import MapKit

@MainActor
final class PlacesService: ObservableObject {
    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search(around location: CLLocation, category: PlaceCategory) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var unique: [String: Place] = [:]

        for term in category.searchTerms {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 25_000,
                longitudinalMeters: 25_000
            )
            request.resultTypes = [.pointOfInterest]

            do {
                let response = try await MKLocalSearch(request: request).start()
                for item in response.mapItems {
                    guard let name = item.name else { continue }
                    let coordinate = item.placemark.coordinate
                    let resultLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let distance = location.distance(from: resultLocation)
                    let address = [
                        item.placemark.thoroughfare,
                        item.placemark.locality
                    ].compactMap { $0 }.joined(separator: ", ")

                    let place = Place(
                        name: name,
                        category: category == .all ? inferredCategory(from: term) : category,
                        coordinate: coordinate,
                        address: address.isEmpty ? "Indirizzo non disponibile" : address,
                        phone: item.phoneNumber,
                        url: item.url,
                        distance: distance
                    )
                    unique["\(name)-\(coordinate.latitude)-\(coordinate.longitude)"] = place
                }
            } catch {
                // Continue with remaining search terms.
            }
        }

        places = unique.values.sorted { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) }
        if places.isEmpty {
            errorMessage = "Nessun luogo LGBTQ+ trovato in questa zona. Prova a cambiare categoria o città."
        }
    }

    private func inferredCategory(from term: String) -> PlaceCategory {
        if term.contains("club") { return .club }
        if term.contains("community") || term.contains("association") { return .community }
        if term.contains("cafe") { return .cafe }
        if term.contains("hotel") { return .hotel }
        if term.contains("beach") { return .beach }
        return .bar
    }
}
