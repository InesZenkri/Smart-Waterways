import SwiftUI
import MapKit

struct HomeView: View {
    @State var viewModel = TripViewModel()
    @State var showTripForm = false
    @State var showTripsList = false
    @State var cardMinimized = false
    @State var dragOffset: CGFloat = 0
    @State var showWaterbodyAlert = false
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            mapView
            
            VStack {
                Spacer()
                if showTripForm {
                    if cardMinimized {
                        minimizedCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        tripFormCard
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                } else if showTripsList {
                    tripsListCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    quickActionsBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onChange(of: viewModel.isSelectingStartPoint) { _, isSelecting in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                cardMinimized = isSelecting
            }
        }
        .onChange(of: viewModel.isSelectingEndPoint) { _, isSelecting in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                cardMinimized = isSelecting
            }
        }
        .onAppear {
            viewModel.generateSampleTrips()
            viewModel.onWaterbodyValidationFailed = {
                showWaterbodyAlert = true
            }
        }
        .alert("Waterbody Required", isPresented: $showWaterbodyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select points on lakes or rivers only. The selected location appears to be on land.")
        }
    }
}
