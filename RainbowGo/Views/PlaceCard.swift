import SwiftUI
import MapKit

struct PlaceCard: View {
    let place: Place
    @AppStorage("distanceUnit") private var distanceUnit = "metric"
    @AppStorage("showVerification") private var showVerification = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: place.category.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 17)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(place.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Text(place.category.rawValue)
                        if let distance = place.distance {
                            Text("•")
                            Text(formattedDistance(distance))
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
                Spacer()
            }

            if showVerification {
                Label(place.matchReason, systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.green.opacity(0.10), in: Capsule())
            }

            HStack(spacing: 10) {
                Button {
                    openDirections()
                } label: {
                    Label("Indicazioni", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let url = place.url {
                    Link(destination: url) {
                        Image(systemName: "safari.fill")
                            .frame(width: 40)
                    }
                    .buttonStyle(.bordered)
                }

                if let phone = place.phone,
                   let phoneURL = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                    Link(destination: phoneURL) {
                        Image(systemName: "phone.fill")
                            .frame(width: 40)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.primary.opacity(0.06)))
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        if distanceUnit == "imperial" {
            return String(format: "%.1f mi", meters / 1609.344)
        }
        return String(format: "%.1f km", meters / 1000)
    }

    private func openDirections() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        item.name = place.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
