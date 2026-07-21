import SwiftUI
import MapKit

struct PlaceCard: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17)
                        .fill(LinearGradient(colors: [.pink.opacity(0.9), .purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: place.category.symbol)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 5) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Label(place.category.rawValue, systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(2)
                }
                Spacer(minLength: 5)
                if let distance = place.distance {
                    Text(distanceText(distance))
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.09), in: Capsule())
                }
            }

            HStack(spacing: 9) {
                Button(action: openDirections) {
                    Label("Indicazioni", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)

                if let phone = place.phone, let url = URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })") {
                    Link(destination: url) { Image(systemName: "phone.fill").frame(width: 24, height: 24) }
                        .buttonStyle(.bordered).tint(.white)
                }
                if let url = place.url {
                    Link(destination: url) { Image(systemName: "safari.fill").frame(width: 24, height: 24) }
                        .buttonStyle(.bordered).tint(.white)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.058), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.085)))
    }

    private func distanceText(_ meters: CLLocationDistance) -> String {
        meters < 1000 ? "\(Int(meters)) m" : String(format: "%.1f km", meters / 1000)
    }

    private func openDirections() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        item.name = place.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}
