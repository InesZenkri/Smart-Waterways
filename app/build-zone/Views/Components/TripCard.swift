import SwiftUI
import CoreLocation

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: vesselIcon)
                    .foregroundStyle(vesselColor)
                Text(trip.vesselType.rawValue)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(trip.startTime, style: .time)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                locationRow(icon: "circle.fill", color: .green, text: formatCoordinate(trip.startPoint))
                locationRow(icon: "circle.fill", color: .red, text: formatCoordinate(trip.endPoint))
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
    
    private func locationRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(color)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func formatCoordinate(_ coord: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coord.latitude, coord.longitude)
    }
    
    private var vesselIcon: String {
        switch trip.vesselType {
        case .motor: return "sailboat.fill"
        case .kayak: return "oar.2.crossed"
        case .sup: return "figure.stand"
        }
    }
    
    private var vesselColor: Color {
        switch trip.vesselType {
        case .motor: return .blue
        case .kayak: return .green
        case .sup: return .orange
        }
    }
}
