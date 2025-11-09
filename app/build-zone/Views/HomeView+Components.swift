import SwiftUI
import MapKit

extension HomeView {
    // MARK: - Quick Actions Bar
    var quickActionsBar: some View {
        HStack(spacing: 16) {
            if !viewModel.trips.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showTripsList = true
                    }
                } label: {
                    Label("Trips", systemImage: "list.bullet")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showTripForm = true
                }
            } label: {
                Label("Plan Trip", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    // MARK: - Trip Form Card
    var tripFormCard: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    locationSection
                    vesselSection
                    timeSection
                    actionButtons
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 620)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -4)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: -2)
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showTripForm = false
                            viewModel.resetForm()
                        }
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
        )
    }
    
    // MARK: - Minimized Card
    var minimizedCard: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select on Map")
                            .font(.headline)
                            .foregroundStyle(.black)
                        Text(viewModel.isSelectingStartPoint ? "Tap to set start point" : "Tap to set end point")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Button {
                        viewModel.isSelectingStartPoint = false
                        viewModel.isSelectingEndPoint = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Point summary
                HStack(spacing: 12) {
                    pointIndicator(
                        color: .green,
                        isSet: viewModel.startPoint != nil,
                        label: "Start"
                    )
                    pointIndicator(
                        color: .red,
                        isSet: viewModel.endPoint != nil,
                        label: "End"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -4)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: -2)
    }
    
    func pointIndicator(color: Color, isSet: Bool, label: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isSet ? color : color.opacity(0.3))
                .frame(width: 12, height: 12)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSet ? .black : .gray)
            if isSet {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSet ? color.opacity(0.15) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSet ? color.opacity(0.3) : Color.gray.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Trips List Card
    var tripsListCard: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Trip History")
                        .font(.title2.bold())
                        .foregroundStyle(.black)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showTripsList = false
                            viewModel.selectedTrip = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                
                List {
                    ForEach(viewModel.trips) { trip in
                        tripHistoryRow(trip: trip)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteTrip(viewModel.trips[index])
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -4)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: -2)
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showTripsList = false
                            viewModel.selectedTrip = nil
                        }
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
        )
    }
    
    func tripHistoryRow(trip: Trip) -> some View {
        let isSelected = viewModel.selectedTrip?.id == trip.id
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isSelected {
                    viewModel.selectedTrip = nil
                } else {
                    viewModel.selectedTrip = trip
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Vessel icon
                ZStack {
                    Circle()
                        .fill(colorForVessel(trip.vesselType).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: vesselIcon(for: trip.vesselType))
                        .font(.title3)
                        .foregroundStyle(colorForVessel(trip.vesselType))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.vesselType.rawValue)
                        .font(.headline)
                        .foregroundStyle(.black)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text(trip.startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text(String(format: "%.4f, %.4f", trip.startPoint.latitude, trip.startPoint.longitude))
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.08) : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Color.blue.opacity(0.4) : Color.gray.opacity(0.25), lineWidth: isSelected ? 2 : 1.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    func vesselIcon(for vessel: VesselType) -> String {
        switch vessel {
        case .motor: return "sailboat.fill"
        case .kayak: return "oar.2.crossed"
        case .sup: return "figure.stand"
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Plan Your Trip")
                .font(.title2.bold())
                .foregroundStyle(.black)
            Text("Navigate Berlin's beautiful waterways")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }
    
    // MARK: - Location Section
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.subheadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Route")
                    .font(.headline)
                    .foregroundStyle(.black)
            }
            
            VStack(spacing: 10) {
                pointButton(
                    title: "Start Point",
                    icon: "circle.fill",
                    iconColor: .green,
                    coordinate: viewModel.startPoint,
                    isSelecting: viewModel.isSelectingStartPoint
                ) {
                    viewModel.isSelectingStartPoint.toggle()
                    viewModel.isSelectingEndPoint = false
                }
                
                pointButton(
                    title: "End Point",
                    icon: "circle.fill",
                    iconColor: .red,
                    coordinate: viewModel.endPoint,
                    isSelecting: viewModel.isSelectingEndPoint
                ) {
                    viewModel.isSelectingEndPoint.toggle()
                    viewModel.isSelectingStartPoint = false
                }
            }
        }
    }
    
    func pointButton(title: String, icon: String, iconColor: Color, coordinate: CLLocationCoordinate2D?, isSelecting: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                    if let coord = coordinate {
                        Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    } else {
                        Text(isSelecting ? "Tap anywhere on map..." : "Tap to select on map")
                            .font(.caption)
                            .foregroundStyle(isSelecting ? .blue : .gray)
                    }
                }
                Spacer()
                if isSelecting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.blue)
                } else {
                    Image(systemName: coordinate != nil ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(coordinate != nil ? iconColor : .gray.opacity(0.4))
                        .font(.system(size: 22))
                }
            }
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            isSelecting 
                            ? Color.blue.opacity(0.08) 
                            : (coordinate != nil ? iconColor.opacity(0.06) : .white)
                        )
                    
                    if isSelecting || coordinate != nil {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isSelecting ? Color.blue.opacity(0.4) : iconColor.opacity(0.3),
                                lineWidth: 1.5
                            )
                    }
                    if !(isSelecting || coordinate != nil) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1.5)
                    }
                }
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Vessel Section
    var vesselSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "ferry.fill")
                    .font(.subheadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Vessel Type")
                    .font(.headline)
                    .foregroundStyle(.black)
            }
            
            HStack(spacing: 10) {
                ForEach(VesselType.allCases, id: \.self) { vessel in
                    vesselButton(for: vessel)
                }
            }
        }
    }
    
    func vesselButton(for vessel: VesselType) -> some View {
        let isSelected = viewModel.selectedVesselType == vessel
        let (icon, color) = vesselInfo(for: vessel)
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedVesselType = vessel
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? color : .gray)
                    .frame(height: 28)
                
                Text(vessel.rawValue.split(separator: " ").first ?? "")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .black : .gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? color.opacity(0.12) : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? color.opacity(0.5) : Color.gray.opacity(0.25), lineWidth: isSelected ? 2 : 1.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    func vesselInfo(for vessel: VesselType) -> (String, Color) {
        switch vessel {
        case .motor: return ("sailboat.fill", .blue)
        case .kayak: return ("oar.2.crossed", .green)
        case .sup: return ("figure.stand", .orange)
        }
    }
    
    // MARK: - Time Section
    var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Departure")
                    .font(.headline)
                    .foregroundStyle(.black)
            }
            
            DatePicker("", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Action Buttons
    var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showTripForm = false
                    viewModel.resetForm()
                }
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            
            Button {
                viewModel.createTrip()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showTripForm = false
                }
            } label: {
                Text("Create Trip")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: viewModel.canCreateTrip ? [.blue, .blue.opacity(0.8)] : [.gray.opacity(0.5), .gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: viewModel.canCreateTrip ? .blue.opacity(0.3) : .clear, radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canCreateTrip)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Map View
    var mapView: some View {
        MapReader { proxy in
            Map(position: .constant(.region(viewModel.region))) {
                // Show selected trip or all trips
                if let selectedTrip = viewModel.selectedTrip {
                    MapPolyline(coordinates: selectedTrip.route)
                        .stroke(colorForVessel(selectedTrip.vesselType), lineWidth: 5)
                    
                    Annotation("Start", coordinate: selectedTrip.startPoint) {
                        Circle()
                            .fill(.green)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    }
                    
                    Annotation("End", coordinate: selectedTrip.endPoint) {
                        Circle()
                            .fill(.red)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    }
                } else {
                    ForEach(viewModel.trips) { trip in
                        MapPolyline(coordinates: trip.route)
                            .stroke(colorForVessel(trip.vesselType).opacity(0.5), lineWidth: 3)
                        
                        Annotation("Start", coordinate: trip.startPoint) {
                            Circle()
                                .fill(.green.opacity(0.7))
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                        
                        Annotation("End", coordinate: trip.endPoint) {
                            Circle()
                                .fill(.red.opacity(0.7))
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                    }
                }
                
                if let start = viewModel.startPoint {
                    Annotation("Start", coordinate: start) {
                        ZStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 32, height: 32)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .green.opacity(0.5), radius: 12, y: 4)
                    }
                }
                
                if let end = viewModel.endPoint {
                    Annotation("End", coordinate: end) {
                        ZStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 32, height: 32)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .red.opacity(0.5), radius: 12, y: 4)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        if viewModel.isSelectingStartPoint || viewModel.isSelectingEndPoint {
                            if let coordinate = proxy.convert(value.location, from: .local) {
                                viewModel.handleMapTap(at: coordinate)
                            }
                        }
                    }
            )
        }
    }
    
    func colorForVessel(_ vessel: VesselType) -> Color {
        switch vessel {
        case .motor: return .blue
        case .kayak: return .green
        case .sup: return .orange
        }
    }
}
