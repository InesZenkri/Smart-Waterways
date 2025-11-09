import Foundation
import CoreLocation
import MapKit

actor WaterbodyValidator {
    private let geocoder = CLGeocoder()
    private let waterKeywords: [String] = [
        "river",
        "lake",
        "canal",
        "spree",
        "havel",
        "wannsee",
        "müggelsee",
        "channel",
        "bay",
        "lagoon",
        "pond",
        "harbor",
        "harbour",
        "fjord",
        "creek",
        "water",
        "reservoir"
    ]
    private let cachePrecision: Double = 0.001
    private let maxReverseGeocodeRequestsPerMinute = 45
    private var waterCache: [CoordinateCacheKey: Bool] = [:]
    private var poiCache: [CoordinateCacheKey: Bool] = [:]
    private var reverseGeocodeTimestamps: [Date] = []
    
    func isCoordinateOnWater(_ coordinate: CLLocationCoordinate2D, allowGeocoder: Bool = true) async -> Bool {
        let key = cacheKey(for: coordinate)
        
        if let cached = waterCache[key] {
            return cached
        }
        
        if let cachedPOI = poiCache[key] {
            if cachedPOI {
                waterCache[key] = true
                return true
            } else if !allowGeocoder {
                return false
            }
        } else {
            let poiResult = await isCoordinateNearWaterPOI(coordinate, cacheKey: key)
            if poiResult {
                waterCache[key] = true
                return true
            } else if !allowGeocoder {
                return false
            }
        }
        
        guard allowGeocoder else {
            return false
        }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        await throttleReverseGeocodingIfNeeded()
        
        if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let placemark = placemarks.first,
           isPlacemarkOnWater(placemark) {
            waterCache[key] = true
            return true
        }
        
        waterCache[key] = false
        return false
    }
    
    func nearestWaterCoordinate(
        from coordinate: CLLocationCoordinate2D,
        maxSearchDistance: CLLocationDistance = 600,
        stepDistance: CLLocationDistance = 60,
        allowGeocoder: Bool = false
    ) async -> CLLocationCoordinate2D? {
        var radius = stepDistance
        let bearings = stride(from: 0.0, to: 360.0, by: 30.0)
        
        while radius <= maxSearchDistance {
            for bearing in bearings {
                let candidate = coordinate.moved(by: radius, bearingDegrees: bearing)
                let allowGeocoderForThisCandidate = allowGeocoder && radius <= stepDistance
                if await isCoordinateOnWater(candidate, allowGeocoder: allowGeocoderForThisCandidate) {
                    return candidate
                }
            }
            radius += stepDistance
        }
        
        return nil
    }
    
    private func isPlacemarkOnWater(_ placemark: CLPlacemark) -> Bool {
        if let inlandWater = placemark.inlandWater, !inlandWater.isEmpty {
            return true
        }
        
        if let ocean = placemark.ocean, !ocean.isEmpty {
            return true
        }
        
        if let areasOfInterest = placemark.areasOfInterest {
            for area in areasOfInterest {
                let lowercasedArea = area.lowercased()
                if waterKeywords.contains(where: { lowercasedArea.contains($0) }) {
                    return true
                }
            }
        }
        
        if placemark.thoroughfare == nil && placemark.subThoroughfare == nil {
            let name = placemark.name?.lowercased() ?? ""
            if name.isEmpty {
                return true
            }
            
            if waterKeywords.contains(where: { name.contains($0) }) {
                return true
            }
        }
        
        return false
    }
    
    private func isCoordinateNearWaterPOI(
        _ coordinate: CLLocationCoordinate2D,
        searchRadius: CLLocationDistance = 400,
        cacheKey: CoordinateCacheKey? = nil
    ) async -> Bool {
        let key = cacheKey ?? self.cacheKey(for: coordinate)
        
        if let cached = poiCache[key] {
            return cached
        }
        
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )
        
        let categories: [MKPointOfInterestCategory] = [
            .marina,
            .beach
        ]
        
        let filter = MKPointOfInterestFilter(including: categories)
        
        let request = MKLocalSearch.Request()
        request.region = region
        request.pointOfInterestFilter = filter
        request.resultTypes = .pointOfInterest
        
        do {
            let response = try await MKLocalSearch(request: request).start()
            let isWater = response.mapItems.contains(where: { item in
                let placemark = item.placemark
                return isPlacemarkOnWater(placemark)
            })
            poiCache[key] = isWater
            return isWater
        } catch {
            return false
        }
    }
}

private extension CLLocationCoordinate2D {
    func moved(by distance: CLLocationDistance, bearingDegrees: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let angularDistance = distance / earthRadius
        let bearing = bearingDegrees * .pi / 180
        
        let latitude = self.latitude * .pi / 180
        let longitude = self.longitude * .pi / 180
        
        let newLatitude = asin(
            sin(latitude) * cos(angularDistance) +
            cos(latitude) * sin(angularDistance) * cos(bearing)
        )
        
        let newLongitude = longitude + atan2(
            sin(bearing) * sin(angularDistance) * cos(latitude),
            cos(angularDistance) - sin(latitude) * sin(newLatitude)
        )
        
        return CLLocationCoordinate2D(
            latitude: newLatitude * 180 / .pi,
            longitude: newLongitude * 180 / .pi
        )
    }
}

private struct CoordinateCacheKey: Hashable {
    let latBin: Int
    let lonBin: Int
}

private extension WaterbodyValidator {
    func cacheKey(for coordinate: CLLocationCoordinate2D) -> CoordinateCacheKey {
        let scale = 1.0 / cachePrecision
        let latBin = Int((coordinate.latitude * scale).rounded())
        let lonBin = Int((coordinate.longitude * scale).rounded())
        return CoordinateCacheKey(latBin: latBin, lonBin: lonBin)
    }
    
    func throttleReverseGeocodingIfNeeded() async {
        let now = Date()
        reverseGeocodeTimestamps = reverseGeocodeTimestamps.filter { now.timeIntervalSince($0) < 60 }
        
        if let earliest = reverseGeocodeTimestamps.first,
           reverseGeocodeTimestamps.count >= maxReverseGeocodeRequestsPerMinute {
            let waitSeconds = 60 - now.timeIntervalSince(earliest)
            if waitSeconds > 0 {
                let nanoseconds = UInt64(waitSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
            
            let refreshedNow = Date()
            reverseGeocodeTimestamps = reverseGeocodeTimestamps.filter { refreshedNow.timeIntervalSince($0) < 60 }
        }
        
        reverseGeocodeTimestamps.append(Date())
    }
}

