// Updated SearchRouteView with optimized layout
import SwiftUI
import MapKit

struct SearchRouteView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var myLocationActive = false
    @Binding var startLocation: String
    @Binding var endLocation: String
    @Binding var selectedStartLocation: LocationSuggestion?
    @Binding var selectedEndLocation: LocationSuggestion?
    @Binding var selectedTransportType: TransportationType
    @Binding var routes: [TransportationType: [RouteInfo]]
    @Binding var isSearching: Bool
    @Binding var hasSearched: Bool
    @Binding var errorMessage: String
    
    @Binding var selectedSpecialRoute: SpecialRouteType
    @State private var showingSpecialRouteInfo = false
    
    let onRouteSelected: (RouteInfo) -> Void
    let onSearchRoutes: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            Text("路线规划")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 8)
            
            // Location input area with optimized layout
            VStack(spacing: 12) {
                // Start location with "Use My Location" inline
                HStack(alignment: .center, spacing: 8) {
                    // Start location field (takes most of the space)
                    EnhancedLocationSearchBar(
                        placeholder: "起点",
                        text: $startLocation,
                        selectedLocation: $selectedStartLocation,
                        icon: "location.circle"
                    )
                    .onChange(of: selectedStartLocation) { _ in
                        checkAutoSearch()
                    }
                    
                    // Compact "Use My Location" button
                    Button(action: {
                        print("使用我的位置 button pressed")
                        myLocationActive = true
                        locationManager.requestLocation()
                    }) {
                        HStack(spacing: 4) {
                            if locationManager.isReverseGeocoding {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "location.fill")
                            }
                            Text(locationManager.isReverseGeocoding ? "定位..." : "我的位置")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    .disabled(locationManager.isReverseGeocoding)
                    .opacity(locationManager.isReverseGeocoding ? 0.6 : 1.0)
                }
                
                // Display location error if needed
                if let locationError = locationManager.locationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(locationError)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // End location with swap button
                HStack(alignment: .center, spacing: 8) {
                    EnhancedLocationSearchBar(
                        placeholder: "终点",
                        text: $endLocation,
                        selectedLocation: $selectedEndLocation,
                        icon: "location.fill"
                    )
                    .onChange(of: selectedEndLocation) { _ in
                        checkAutoSearch()
                    }
                    
                    // Swap button (more compact)
                    Button(action: {
                        let tempLocation = startLocation
                        let tempSelected = selectedStartLocation
                        
                        startLocation = endLocation
                        selectedStartLocation = selectedEndLocation
                        
                        endLocation = tempLocation
                        selectedEndLocation = tempSelected
                        
                        checkAutoSearch()
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // Special route selector (more compact)
            VStack(spacing: 8) {
                HStack {
                    Text("路线偏好")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingSpecialRouteInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                SpecialRouteSelector(selectedSpecialRoute: $selectedSpecialRoute)
                    .padding(.horizontal)
                    .onChange(of: selectedSpecialRoute) { _, newValue in
                        if hasSearched && canSearch {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSearchRoutes()
                            }
                        }
                    }
            }
            .padding(.top, 8)
            
            // Search button
            if canSearch && !hasSearched {
                Button(action: {
                    onSearchRoutes()
                }) {
                    HStack {
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isSearching ? "搜索中..." : "搜索路线")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSearching ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isSearching)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Selected location info (more compact)
            if selectedStartLocation != nil || selectedEndLocation != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let start = selectedStartLocation {
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(.green)
                                .font(.caption2)
                            Text("起点: \(start.displayText)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    if let end = selectedEndLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                                .font(.caption2)
                            Text("终点: \(end.displayText)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    if selectedSpecialRoute != .none {
                        HStack {
                            Image(systemName: selectedSpecialRoute.icon)
                                .foregroundColor(selectedSpecialRoute.color)
                                .font(.caption2)
                            Text("偏好: \(selectedSpecialRoute.rawValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .font(.caption)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Route selection area (made larger by reducing space above)
            if hasSearched && !routes.isEmpty {
                VStack(spacing: 0) {
                    // Transport type tabs
                    HStack(spacing: 0) {
                        ForEach(TransportationType.allCases, id: \.self) { type in
                            TransportTab(
                                type: type,
                                isSelected: selectedTransportType == type,
                                routeCount: routes[type]?.count ?? 0,
                                isEnabled: true,
                                action: {
                                    selectedTransportType = type
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // Route list (expanded)
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if let routeList = routes[selectedTransportType], !routeList.isEmpty {
                                ForEach(routeList, id: \.id) { route in
                                    Button(action: {
                                        onRouteSelected(route)
                                    }) {
                                        RouteCard(route: route, onGoTapped: {
                                            onRouteSelected(route)
                                        })
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                VStack {
                                    Image(systemName: selectedTransportType.icon)
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("正在为您查找\(selectedTransportType.rawValue)路线...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                }
            } else if hasSearched && routes.isEmpty && !isSearching {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("未找到可用路线")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else if !hasSearched {
                Spacer()
            }
        }
        .onChange(of: locationManager.currentLocationName) { _, newValue in
            guard myLocationActive,
                  let coord = locationManager.currentLocation,
                  let locationName = newValue else { return }
            
            let myLoc = LocationSuggestion(
                title: locationName,
                subtitle: "",
                coordinate: coord,
                completion: nil
            )
            startLocation = myLoc.displayText
            selectedStartLocation = myLoc
            myLocationActive = false
            checkAutoSearch()
        }
        .sheet(isPresented: $showingSpecialRouteInfo) {
            SpecialRouteInfoView()
        }
    }
    
    // Check if can search
    private var canSearch: Bool {
        return selectedStartLocation != nil && selectedEndLocation != nil
    }
    
    // Auto search check
    private func checkAutoSearch() {
        if canSearch && !hasSearched && !isSearching {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.canSearch && !self.hasSearched && !self.isSearching {
                    self.onSearchRoutes()
                }
            }
        }
    }
}

// 特殊路线信息视图
struct SpecialRouteInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("路线偏好说明")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(SpecialRouteType.allCases, id: \.self) { routeType in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: routeType.icon)
                                    .foregroundColor(routeType.color)
                                    .font(.title3)
                                
                                Text(routeType.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(routeType.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                ForEach(routeType.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(routeType.color.opacity(0.15))
                                        )
                                        .foregroundColor(routeType.color)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("路线偏好")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
