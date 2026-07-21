import Foundation
import MapKit

struct Place: Identifiable, Hashable {
    let id: String
    let name: String
    let category: PlaceCategory
    let coordinate: CLLocationCoordinate2D
    let address: String
    let city: String
    let phone: String?
    let url: URL?
    let distance: CLLocationDistance?
    let matchReason: String

    static func == (lhs: Place, rhs: Place) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum PlaceCategory: String, CaseIterable, Identifiable {
    case all = "Tutti"
    case bar = "Bar"
    case club = "Club"
    case sauna = "Saune"
    case community = "Community"
    case hotel = "Hotel"
    case beach = "Spiagge"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: return "sparkles"
        case .bar: return "wineglass.fill"
        case .club: return "music.note"
        case .sauna: return "drop.degreesign.fill"
        case .community: return "person.3.fill"
        case .hotel: return "bed.double.fill"
        case .beach: return "beach.umbrella.fill"
        }
    }

    var searchTerms: [String] {
        switch self {
        case .all: return ["gay bar", "LGBTQ bar", "queer club", "gay sauna", "LGBTQ center", "gay hotel", "gay beach"]
        case .bar: return ["gay bar", "LGBTQ bar", "queer bar"]
        case .club: return ["gay club", "LGBTQ nightclub", "queer club"]
        case .sauna: return ["gay sauna", "LGBTQ sauna"]
        case .community: return ["LGBTQ center", "gay association", "queer community"]
        case .hotel: return ["gay hotel", "LGBTQ hotel"]
        case .beach: return ["gay beach", "LGBTQ beach"]
        }
    }
}
