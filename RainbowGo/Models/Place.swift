import Foundation
import MapKit

struct Place: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: PlaceCategory
    let coordinate: CLLocationCoordinate2D
    let address: String
    let phone: String?
    let url: URL?
    let distance: CLLocationDistance?

    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.name == rhs.name && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}

enum PlaceCategory: String, CaseIterable, Identifiable {
    case all = "Tutti"
    case bar = "Bar"
    case club = "Club"
    case cafe = "Café"
    case community = "Community"
    case hotel = "Hotel"
    case beach = "Spiagge"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: return "sparkles"
        case .bar: return "wineglass.fill"
        case .club: return "music.note"
        case .cafe: return "cup.and.saucer.fill"
        case .community: return "person.3.fill"
        case .hotel: return "bed.double.fill"
        case .beach: return "beach.umbrella.fill"
        }
    }

    var searchTerms: [String] {
        switch self {
        case .all: return ["gay bar", "LGBTQ bar", "queer club", "LGBTQ community center", "gay friendly cafe"]
        case .bar: return ["gay bar", "LGBTQ bar", "queer bar"]
        case .club: return ["gay club", "LGBTQ nightclub", "queer club"]
        case .cafe: return ["LGBTQ cafe", "gay friendly cafe", "queer cafe"]
        case .community: return ["LGBTQ community center", "gay association", "queer community"]
        case .hotel: return ["gay friendly hotel", "LGBTQ hotel"]
        case .beach: return ["gay beach", "LGBTQ beach"]
        }
    }
}
