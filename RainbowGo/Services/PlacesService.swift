import Foundation
import MapKit

@MainActor
final class PlacesService: ObservableObject {
    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search(around location: CLLocation, cityName: String, category: PlaceCategory, radiusKm: Double) async {
        isLoading = true
        errorMessage = nil
        places = []
        defer { isLoading = false }

        var unique: [String: Place] = [:]
        let radius = max(4_000, min(radiusKm * 1_000, 30_000))

        for term in category.searchTerms {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(term) \(cityName)"
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            )
            request.resultTypes = [.pointOfInterest]

            do {
                let response = try await MKLocalSearch(request: request).start()
                for item in response.mapItems {
                    guard let name = item.name else { continue }
                    let placemarkCity = item.placemark.locality
                        ?? item.placemark.subAdministrativeArea
                        ?? item.placemark.administrativeArea
                        ?? ""

                    // Mostra esclusivamente i risultati appartenenti alla città selezionata.
                    guard sameCity(placemarkCity, cityName) else { continue }

                    let coordinate = item.placemark.coordinate
                    let resultLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let distance = location.distance(from: resultLocation)
                    guard distance <= radius * 1.35 else { continue }

                    let address = [
                        item.placemark.thoroughfare,
                        item.placemark.subThoroughfare,
                        item.placemark.locality
                    ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")

                    let place = Place(
                        name: name,
                        category: category == .all ? inferredCategory(from: term) : category,
                        coordinate: coordinate,
                        address: address.isEmpty ? cityName : address,
                        city: placemarkCity,
                        phone: item.phoneNumber,
                        url: item.url,
                        distance: distance
                    )
                    unique["\(name.lowercased())-\(coordinate.latitude.rounded(toPlaces: 4))-\(coordinate.longitude.rounded(toPlaces: 4))"] = place
                }
            } catch {
                continue
            }
        }

        places = unique.values.sorted {
            ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude)
        }

        if places.isEmpty {
            errorMessage = "Non risultano luoghi LGBTQ+ nella città di \(cityName) per questa categoria."
        }
    }

    private func sameCity(_ result: String, _ selected: String) -> Bool {
        let a = normalized(result)
        let b = normalized(selected)
        guard !a.isEmpty, !b.isEmpty else { return false }
        return a == b || a.contains(b) || b.contains(a)
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "citta di ", with: "")
            .replacingOccurrences(of: "city of ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func inferredCategory(from term: String) -> PlaceCategory {
        let value = term.lowercased()
        if value.contains("club") || value.contains("nightclub") { return .club }
        if value.contains("community") || value.contains("association") || value.contains("centre") { return .community }
        if value.contains("café") || value.contains("cafe") { return .cafe }
        if value.contains("hotel") { return .hotel }
        if value.contains("beach") { return .beach }
        return .bar
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
