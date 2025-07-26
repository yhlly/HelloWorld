//
//  ContentView.swift
//  HelloWorld
//
//  主视图 - 协调各个界面的显示 - 支持特殊路线
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var currentState: AppState = .search
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var selectedStartLocation: LocationSuggestion?
    @State private var selectedEndLocation: LocationSuggestion?
    @State private var selectedTransportType: TransportationType = .driving
    @State private var routes: [TransportationType: [RouteInfo]] = [:]
    @State private var selectedRoute: RouteInfo?
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage = ""
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D?
    @State private var currentLocationIndex = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // 新增特殊路线状态
    @State private var selectedSpecialRoute: SpecialRouteType = .none
    
    var body: some View {
        NavigationView {
            switch currentState {
            case .search:
                SearchRouteView(
                    startLocation: $startLocation,
                    endLocation: $endLocation,
                    selectedStartLocation: $selectedStartLocation,
                    selectedEndLocation: $selectedEndLocation,
                    selectedTransportType: $selectedTransportType,
                    routes: $routes,
                    isSearching: $isSearching,
                    hasSearched: $hasSearched,
                    errorMessage: $errorMessage,
                    onRouteSelected: { route in
                        selectedRoute = route
                        currentLocationIndex = 0
                        currentState = .routePreview
                    },
                    onSearchRoutes: {
                        searchAllRoutes()
                    }
                )
            case .routePreview:
                RoutePreviewView(
                    selectedRoute: selectedRoute,
                    region: $region,
                    startCoordinate: $startCoordinate,
                    endCoordinate: $endCoordinate,
                    onBackTapped: {
                        currentState = .search
                    },
                    onPreviewTapped: {
                        currentState = .map3D
                    },
                    onPlayTapped: {
                        currentState = .arNavigation
                    }
                )
            case .map3D:
                Map3DNavigationView(
                    selectedRoute: selectedRoute,
                    region: $region,
                    startCoordinate: $startCoordinate,
                    endCoordinate: $endCoordinate,
                    currentLocationIndex: $currentLocationIndex,
                    onBackTapped: {
                        currentState = .routePreview
                    },
                    onStartNavigationTapped: {
                        currentState = .arNavigation
                    }
                )
            case .arNavigation:
                ZStack {
                    if let route = selectedRoute {
                        ARNavigationView(
                            route: route,
                            currentLocationIndex: $currentLocationIndex,
                            region: $region,
                            startCoordinate: $startCoordinate,
                            endCoordinate: $endCoordinate
                        )
                    }
                    
                    // 顶部返回按钮
                    VStack {
                        HStack {
                            Button(action: {
                                currentState = .routePreview
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                currentState = .map3D
                            }) {
                                Image(systemName: "map")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                        }
                        .padding()
                        
                        Spacer()
                    }
                }
            }
        }
        .onTapGesture {
            // 点击任何地方隐藏键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // 搜索所有路线（支持特殊路线）
    func searchAllRoutes() {
        guard let startSuggestion = selectedStartLocation,
              let endSuggestion = selectedEndLocation else {
            errorMessage = "请选择起点和终点"
            return
        }
        
        isSearching = true
        errorMessage = ""
        routes.removeAll()
        hasSearched = false
        
        // 获取起点坐标
        let searchManager = LocationSearchManager()
        searchManager.getCoordinate(for: startSuggestion) { startCoord in
            guard let startCoord = startCoord else {
                DispatchQueue.main.async {
                    self.errorMessage = "无法获取起点坐标"
                    self.isSearching = false
                }
                return
            }
            
            // 获取终点坐标
            searchManager.getCoordinate(for: endSuggestion) { endCoord in
                guard let endCoord = endCoord else {
                    DispatchQueue.main.async {
                        self.errorMessage = "无法获取终点坐标"
                        self.isSearching = false
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.startCoordinate = startCoord
                    self.endCoordinate = endCoord
                    self.calculateRoutesForAllTransportTypes(from: startCoord, to: endCoord)
                }
            }
        }
    }
    
    // 为所有交通方式计算路线（支持特殊路线）
    func calculateRoutesForAllTransportTypes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let group = DispatchGroup()
        
        for transportType in TransportationType.allCases {
            group.enter()
            
            // 创建特殊路线配置
            let specialConfig = SpecialRouteConfig(
                specialType: selectedSpecialRoute,
                transportType: transportType
            )
            
            RouteService.shared.calculateRouteWithSpecialType(
                from: start,
                to: end,
                transportType: transportType,
                specialConfig: specialConfig
            ) { routeInfos in
                DispatchQueue.main.async {
                    self.routes[transportType] = routeInfos
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isSearching = false
            self.hasSearched = true
        }
    }
}

#Preview {
    ContentView()
}
