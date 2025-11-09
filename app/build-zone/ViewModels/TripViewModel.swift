import Foundation
import CoreLocation
import MapKit

@Observable
class TripViewModel {
    var trips: [Trip] = []
    var selectedVesselType: VesselType = .kayak
    var startTime: Date = Date()
    var startPoint: CLLocationCoordinate2D?
    var endPoint: CLLocationCoordinate2D?
    var isSelectingStartPoint = false
    var isSelectingEndPoint = false
    var selectedTrip: Trip?
    var onWaterbodyValidationFailed: (() -> Void)?
    
    var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    
    private let waterValidator: WaterbodyValidator
    private let waterRoutePlanner: WaterRoutePlanner
    
    init(waterValidator: WaterbodyValidator = WaterbodyValidator()) {
        self.waterValidator = waterValidator
        self.waterRoutePlanner = WaterRoutePlanner(validator: waterValidator)
    }
    
    var canCreateTrip: Bool {
        startPoint != nil && endPoint != nil
    }
    
    func createTrip() {
        guard let start = startPoint, let end = endPoint else { return }
        
        // Calculate waterway route asynchronously
        calculateWaterwayRoute(from: start, to: end) { [weak self] routeCoordinates in
            guard let self = self else { return }
            
            let trip = Trip(
                startPoint: start,
                endPoint: end,
                startTime: self.startTime,
                vesselType: self.selectedVesselType,
                route: routeCoordinates
            )
            
            self.trips.insert(trip, at: 0)
            self.resetForm()
        }
    }
    
    private func calculateWaterwayRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
        Task {
            let routeCoordinates = await waterRoutePlanner.planRoute(from: start, to: end)
            await MainActor.run {
                completion(routeCoordinates)
            }
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        if selectedTrip?.id == trip.id {
            selectedTrip = nil
        }
        trips.removeAll { $0.id == trip.id }
    }
    
    func resetForm() {
        startPoint = nil
        endPoint = nil
        startTime = Date()
        isSelectingStartPoint = false
        isSelectingEndPoint = false
    }
    
    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        // Validate waterbody
        validateWaterbody(at: coordinate) { [weak self] isValid in
            guard let self = self else { return }
            
            if !isValid {
                self.onWaterbodyValidationFailed?()
                return
            }
            
            if self.isSelectingStartPoint {
                self.startPoint = coordinate
                // Auto-advance to end point selection
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isSelectingStartPoint = false
                    if self.endPoint == nil {
                        self.isSelectingEndPoint = true
                    }
                }
            } else if self.isSelectingEndPoint {
                self.endPoint = coordinate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isSelectingEndPoint = false
                }
            }
        }
    }
    
    private func validateWaterbody(at coordinate: CLLocationCoordinate2D, completion: @escaping (Bool) -> Void) {
        Task {
            let isWater = await waterValidator.isCoordinateOnWater(coordinate)
            await MainActor.run {
                completion(isWater)
            }
        }
    }
    
    func generateSampleTrips() {
        // Sample trip 1: Spree River - Museum Island to Treptower Park
        trips.append(Trip(
            startPoint: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.3988),
            endPoint: CLLocationCoordinate2D(latitude: 52.4914, longitude: 13.4648),
            startTime: Date().addingTimeInterval(-3600),
            vesselType: .kayak
        ))
        
        // Sample trip 2: Havel - Wannsee area
        trips.append(Trip(
            startPoint: CLLocationCoordinate2D(latitude: 52.4333, longitude: 13.1667),
            endPoint: CLLocationCoordinate2D(latitude: 52.4500, longitude: 13.2000),
            startTime: Date().addingTimeInterval(-7200),
            vesselType: .sup
        ))
    }
}
