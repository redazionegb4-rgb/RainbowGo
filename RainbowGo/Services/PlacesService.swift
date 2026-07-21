import Foundation
import MapKit

@MainActor
final class PlacesService: ObservableObject {
    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let identityKeywords = [
        "gay", "lgbt", "lgbtq", "queer", "pride", "rainbow", "lesbian",
        "transgender", "trans ", "omosessual", "arcigay", "cogam", "lambda"
    ]

    func search(around location: CLLocation, cityName: String, category: PlaceCategory, radiusKm: Double) async {
        isLoading = true
        errorMessage = nil
        places = []
        defer { isLoading = false }

        let radius = max(4_000, min(radiusKm * 1_000, 30_000))
        var unique: [String: Place] = [:]

        for term in category.searchTerms {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(term) \(cityName)"
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            )
            request.resultTypes = [.pointOfInterest]

            guard let response = try? await MKLocalSearch(request: request).start() else { continue }

            for item in response.mapItems {
                guard let name = item.name else { continue }
                let placemarkCity = item.placemark.locality
                    ?? item.placemark.subAdministrativeArea
                    ?? item.placemark.administrativeArea
                    ?? ""

                guard sameCity(placemarkCity, cityName) else { continue }

                let coordinate = item.placemark.coordinate
                let resultLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let distance = location.distance(from: resultLocation)
                guard distance <= radius * 1.20 else { continue }

                let searchableText = [
                    name,
                    item.url?.absoluteString ?? "",
                    item.placemark.title ?? "",
                    term
                ].joined(separator: " ").lowercased()

                guard let keyword = identityKeywords.first(where: { searchableText.contains($0) }) else {
                    continue
                }

                // Il termine della query da solo non basta: il nome, il sito o l'indirizzo
                // devono contenere un riferimento LGBTQ+ esplicito.
                let sourceText = [name, item.url?.absoluteString ?? "", item.placemark.title ?? ""]
                    .joined(separator: " ")
                    .lowercased()
                guard identityKeywords.contains(where: { sourceText.contains($0) }) else { continue }

                let address = [
                    item.placemark.thoroughfare,
                    item.placemark.subThoroughfare,
                    item.placemark.locality
                ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")

                let categoryValue = category == .all ? inferredCategory(from: term) : category
                let key = "\(name.lowercased())-\(coordinate.latitude.rounded(toPlaces: 4))-\(coordinate.longitude.rounded(toPlaces: 4))"
                unique[key] = Place(
                    id: key,
                    name: name,
                    category: categoryValue,
                    coordinate: coordinate,
                    address: address.isEmpty ? cityName : address,
                    city: placemarkCity,
                    phone: item.phoneNumber,
                    url: item.url,
                    distance: distance,
                    matchReason: "Verificato tramite riferimento \(keyword.uppercased())"
                )
            }
        }

        places = unique.values.sorted {
            ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude)
        }

        if places.isEmpty {
            errorMessage = "Non ho trovato luoghi con un riferimento LGBTQ+ esplicito a \(cityName). Per evitare locali generici, RainbowGo esclude i risultati non verificabili."
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
        if value.contains("sauna") { return .sauna }
        if value.contains("community") || value.contains("association") || value.contains("center") { return .community }
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
