// Updated ContentView with better collection button placement
import SwiftUI
import MapKit
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var collectionManager: CollectionManager?
    
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
    
    // 特殊路线状态
    @State private var selectedSpecialRoute: SpecialRouteType = .none
    
    // 新增：控制收集页面的显示
    @State private var showingCollection = false
    
    var body: some View {
        NavigationView {
            switch currentState {
            case .search:
                ZStack(alignment: .topTrailing) { // Align ZStack to top right
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
                        selectedSpecialRoute: $selectedSpecialRoute,
                        onRouteSelected: { route in
                            selectedRoute = route
                            currentLocationIndex = 0
                            currentState = .routePreview
                        },
                        onSearchRoutes: {
                            searchAllRoutes()
                        }
                    )
                    
                    // 新增：右上角收藏按钮 - positioned to avoid overlap
                    Button(action: {
                        showingCollection = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "bag.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            if let manager = collectionManager {
                                Text("\(manager.getCollectionStats().total)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.top, 10) // Move closer to top
                    .padding(.trailing, 16)
                    .zIndex(1) // Ensure it's above other content
                }
                .sheet(isPresented: $showingCollection) {
                    if let manager = collectionManager {
                        CollectionView(collectionManager: manager)
                    } else {
                        // 显示加载视图
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("正在加载收集数据...")
                                .padding(.top)
                        }
                    }
                }
                
            case .routePreview:
                RoutePreviewView(
                    selectedRoute: selectedRoute,
                    region: $region,
                    startCoordinate: $startCoordinate,
                    endCoordinate: $endCoordinate,
                    onBackTapped: {
                        currentState = .search
                    },
                    onPlayTapped: {
                        currentState = .arNavigation
                    },
                    onSimulateTapped: {
                        currentState = .routeSimulation
                    }
                )
            case .routeSimulation:
                // 路线模拟视图
                if let route = selectedRoute {
                    RouteSimulationView(
                        route: route,
                        region: $region,
                        startCoordinate: $startCoordinate,
                        endCoordinate: $endCoordinate,
                        onBackTapped: {
                            currentState = .routePreview
                        },
                        onStartRealNavigation: {
                            currentState = .arNavigation
                        }
                    )
                } else {
                    // 回退处理
                    Text("路线数据不可用")
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                currentState = .routePreview
                            }
                        }
                }
            case .arNavigation:
                if let route = selectedRoute, let manager = collectionManager {
                    EnhancedARNavigationView(
                        route: route,
                        currentLocationIndex: $currentLocationIndex,
                        region: $region,
                        startCoordinate: $startCoordinate,
                        endCoordinate: $endCoordinate,
                        collectionManager: manager,
                        onBackTapped: {
                            currentState = .routePreview
                        }
                    )
                    .onDisappear {
                        // 确保从导航页面离开时，重置相关状态
                        print("导航视图消失，重置状态")
                    }
                } else {
                    // 如果CollectionManager还没初始化，显示加载视图
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在初始化收集系统...")
                            .padding(.top)
                    }
                }
            }
        }
        .onTapGesture {
            // 点击任何地方隐藏键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            initializeCollectionManager()
        }
    }
    
    // 初始化收集管理器
    private func initializeCollectionManager() {
        if collectionManager == nil {
            collectionManager = CollectionManager(modelContext: modelContext)
            print("🎯 CollectionManager 初始化完成")
        }
    }
    
    // 搜索所有路线（支持特殊路线）
    func searchAllRoutes() {
        guard let startSuggestion = selectedStartLocation,
              let endSuggestion = selectedEndLocation else {
            errorMessage = "请选择起点和终点"
            return
        }
        
        print("🔧 DEBUG: searchAllRoutes 开始")
        print("  🎯 当前选择的特殊路线: \(selectedSpecialRoute.rawValue)")
        print("  📍 起点: \(startSuggestion.displayText)")
        print("  📍 终点: \(endSuggestion.displayText)")
        
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
                    print("🔧 DEBUG: 开始计算路线，特殊路线类型: \(self.selectedSpecialRoute.rawValue)")
                    self.calculateRoutesForAllTransportTypes(from: startCoord, to: endCoord)
                }
            }
        }
    }
    
    // 为所有交通方式计算路线（支持特殊路线）
    func calculateRoutesForAllTransportTypes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let group = DispatchGroup()
        
        print("🔧 DEBUG: calculateRoutesForAllTransportTypes")
        print("  🎯 使用的特殊路线类型: \(selectedSpecialRoute.rawValue)")
        
        for transportType in TransportationType.allCases {
            group.enter()
            
            // 创建特殊路线配置
            let specialConfig = SpecialRouteConfig(
                specialType: selectedSpecialRoute,
                transportType: transportType
            )
            
            print("🔧 DEBUG: 为\(transportType.rawValue)创建配置:")
            print("  🎯 特殊路线类型: \(specialConfig.specialType.rawValue)")
            print("  🔍 搜索关键词: \(specialConfig.priorityKeywords)")
            
            RouteService.shared.calculateRouteWithSpecialType(
                from: start,
                to: end,
                transportType: transportType,
                specialConfig: specialConfig
            ) { routeInfos in
                DispatchQueue.main.async {
                    print("🔧 DEBUG: \(transportType.rawValue)路线计算完成，返回\(routeInfos.count)条路线")
                    self.routes[transportType] = routeInfos
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            print("🔧 DEBUG: 所有路线计算完成")
            print("  📊 最终结果:")
            for (transport, routeList) in self.routes {
                print("    \(transport.rawValue): \(routeList.count)条路线")
                for (index, route) in routeList.enumerated() {
                    print("      \(index + 1). \(route.type.rawValue) - 特殊类型: \(route.specialRouteType.rawValue)")
                }
            }
            
            self.isSearching = false
            self.hasSearched = true
        }
    }
}
