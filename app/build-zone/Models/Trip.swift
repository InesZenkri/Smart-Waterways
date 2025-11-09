import Foundation
import CoreLocation

enum VesselType: String, CaseIterable {
    case motor = "Motor Boat"
    case kayak = "Kayak"
    case sup = "Stand-Up Paddle"
    
    var color: String {
        switch self {
        case .motor: return "motorBlue"
        case .kayak: return "kayakGreen"
        case .sup: return "supOrange"
        }
    }
}

struct Trip: Identifiable {
    let id: UUID
    var startPoint: CLLocationCoordinate2D
    var endPoint: CLLocationCoordinate2D
    var startTime: Date
    var vesselType: VesselType
    var route: [CLLocationCoordinate2D]
    
    init(
        id: UUID = UUID(),
        startPoint: CLLocationCoordinate2D,
        endPoint: CLLocationCoordinate2D,
        startTime: Date = Date(),
        vesselType: VesselType,
        route: [CLLocationCoordinate2D]? = nil
    ) {
        self.id = id
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.startTime = startTime
        self.vesselType = vesselType
        self.route = route ?? Trip.generateWaterwayRoute(from: startPoint, to: endPoint)
    }
    
    static func generateWaterwayRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var route: [CLLocationCoordinate2D] = []
        
        // Create a more organic waterway path with natural curves
        let steps = 50 // More points for smoother curves
        
        // Generate control points for a bezier-like curve
        let midLat = (start.latitude + end.latitude) / 2
        let midLon = (start.longitude + end.longitude) / 2
        
        // Add perpendicular offset for natural river curve
        let deltaLat = end.latitude - start.latitude
        let deltaLon = end.longitude - start.longitude
        let distance = sqrt(deltaLat * deltaLat + deltaLon * deltaLon)
        
        // Control point offset (perpendicular to the line)
        let offsetFactor = distance * 0.3
        let controlLat = midLat - deltaLon * offsetFactor
        let controlLon = midLon + deltaLat * offsetFactor
        
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            
            // Quadratic bezier curve to simulate river meandering
            let lat = (1 - t) * (1 - t) * start.latitude +
                      2 * (1 - t) * t * controlLat +
                      t * t * end.latitude
            
            let lon = (1 - t) * (1 - t) * start.longitude +
                      2 * (1 - t) * t * controlLon +
                      t * t * end.longitude
            
            // Add small random variations to simulate natural waterway
            let variation = sin(t * .pi * 4) * 0.0005 * distance
            
            route.append(CLLocationCoordinate2D(
                latitude: lat + variation,
                longitude: lon
            ))
        }
        
        return route
    }
}
