import Foundation
import MapKit
import CoreLocation

final class WaterRoutePlanner {
    private let validator: WaterbodyValidator
    private let samplingDistance: CLLocationDistance
    private let mergeThreshold: CLLocationDistance
    private let validationSpacing: CLLocationDistance
    
    init(
        validator: WaterbodyValidator = WaterbodyValidator(),
        samplingDistance: CLLocationDistance = 120,
        mergeThreshold: CLLocationDistance = 25,
        validationSpacing: CLLocationDistance = 120
    ) {
        self.validator = validator
        self.samplingDistance = samplingDistance
        self.mergeThreshold = mergeThreshold
        self.validationSpacing = validationSpacing
    }
    
    func planRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> [CLLocationCoordinate2D] {
        if let waterRoute = await mapKitWaterRoute(from: start, to: end) {
            return waterRoute
        }
        
        let synthetic = Trip.generateWaterwayRoute(from: start, to: end)
        let waterOnly = await ensureWaterPoints(synthetic)
        
        if waterOnly.count >= 2 {
            return deduplicatedRoute(waterOnly, start: start, end: end)
        } else {
            return [start, end]
        }
    }
    
    private func mapKitWaterRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> [CLLocationCoordinate2D]? {
        do {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
            request.transportType = [.walking]
            
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            
            guard let route = response.routes.sorted(by: { $0.expectedTravelTime < $1.expectedTravelTime }).first else {
                return nil
            }
            
            let sampledCandidates = samplePolyline(route.polyline, start: start, end: end)
            let waterOnly = await ensureWaterPoints(sampledCandidates)
            
            guard waterOnly.count >= 2 else {
                return nil
            }
            
            return deduplicatedRoute(waterOnly, start: start, end: end)
        } catch {
            return nil
        }
    }
    
    private func samplePolyline(
        _ polyline: MKPolyline,
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        guard polyline.pointCount > 1 else {
            return [start, end]
        }
        
        var samples: [CLLocationCoordinate2D] = [start]
        let points = polyline.points()
        var previousCoordinate = start
        
        for index in 0..<polyline.pointCount {
            let mapPoint = points[index]
            let coordinate = mapPoint.coordinate
            
            let distance = previousCoordinate.distance(to: coordinate)
            if distance > samplingDistance {
                let segments = max(1, Int(distance / samplingDistance))
                for step in 1...segments {
                    let fraction = Double(step) / Double(segments)
                    let interpolated = previousCoordinate.interpolate(to: coordinate, fraction: fraction)
                    samples.append(interpolated)
                }
            } else {
                samples.append(coordinate)
            }
            
            previousCoordinate = coordinate
        }
        
        if samples.last?.distance(to: end) ?? .greatestFiniteMagnitude > mergeThreshold {
            samples.append(end)
        } else {
            samples[samples.count - 1] = end
        }
        
        return samples
    }
    
    private func ensureWaterPoints(_ candidates: [CLLocationCoordinate2D]) async -> [CLLocationCoordinate2D] {
        var waterCoordinates: [CLLocationCoordinate2D] = []
        var lastValidatedCoordinate: CLLocationCoordinate2D?
        
        for coordinate in candidates {
            if let lastValidated = lastValidatedCoordinate,
               lastValidated.distance(to: coordinate) < validationSpacing {
                continue
            }
            
            lastValidatedCoordinate = coordinate
            
            if await validator.isCoordinateOnWater(coordinate, allowGeocoder: false) {
                waterCoordinates.appendIfFarEnough(coordinate, threshold: mergeThreshold)
                continue
            }
            
            if let nearbyWater = await validator.nearestWaterCoordinate(from: coordinate, allowGeocoder: false) {
                waterCoordinates.appendIfFarEnough(nearbyWater, threshold: mergeThreshold)
            }
        }
        
        return waterCoordinates
    }
    
    private func deduplicatedRoute(
        _ coordinates: [CLLocationCoordinate2D],
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        var route = coordinates
        
        if let first = route.first, first.distance(to: start) > mergeThreshold {
            route.insert(start, at: 0)
        } else {
            route[0] = start
        }
        
        if let last = route.last, last.distance(to: end) > mergeThreshold {
            route.append(end)
        } else {
            route[route.count - 1] = end
        }
        
        return route
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let current = CLLocation(latitude: latitude, longitude: longitude)
        let target = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return current.distance(from: target)
    }
    
    func interpolate(to other: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude + (other.latitude - latitude) * fraction,
            longitude: longitude + (other.longitude - longitude) * fraction
        )
    }
}

private extension Array where Element == CLLocationCoordinate2D {
    mutating func appendIfFarEnough(_ coordinate: CLLocationCoordinate2D, threshold: CLLocationDistance) {
        guard let last = last else {
            append(coordinate)
            return
        }
        
        if last.distance(to: coordinate) >= threshold {
            append(coordinate)
        } else {
            self[count - 1] = coordinate
        }
    }
}

