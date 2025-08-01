//
//  EnhancedARNavigationView.swift
//  HelloWorld
//
//  完整的增强AR导航视图，集成收集功能和详细Debug
//

import SwiftUI
import ARKit
import SceneKit
import MapKit
import SwiftData

// 增强的AR导航视图
struct EnhancedARNavigationView: View {
    let route: RouteInfo
    @Binding var currentLocationIndex: Int
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    
    let collectionManager: CollectionManager
    let onBackTapped: () -> Void
    
    @State private var isNavigating = false
    @State private var currentSpeed = "0"
    @State private var remainingTime = ""
    @State private var remainingDistance = ""
    @State private var timer: Timer?
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var showingCollection = false
    @State private var showingCollectionSuccess = false
    @State private var lastCollectedItem: String = ""
    @State private var showingCollectiblePopup = false
    @State private var selectedCollectible: CollectiblePoint?
    @State private var debugInfo = "Debug: 初始化中..."
    
    // 是否使用AR模式
    @State private var useARMode = true
    
    private var currentInstruction: NavigationInstruction? {
        guard currentLocationIndex < route.instructions.count else { return nil }
        return route.instructions[currentLocationIndex]
    }
    
    private var collectiblesInRange: [CollectiblePoint] {
        guard let userLocation = userLocation else { return [] }
        let collectibles = collectionManager.collectiblesInRange(of: userLocation)
        print("🎯 DEBUG: 当前范围内收集点数量: \(collectibles.count)")
        return collectibles
    }
    
    var body: some View {
        ZStack {
            // AR场景视图或地图视图
            if useARMode && ARWorldTrackingConfiguration.isSupported {
                EnhancedARSceneView(
                    currentInstruction: .constant(currentInstruction),
                    isNavigating: $isNavigating,
                    userLocation: $userLocation,
                    collectionManager: collectionManager,
                    route: route,
                    onCollectionTapped: { collectible in
                        print("🎯 DEBUG: AR点击收集点: \(collectible.name)")
                        handleCollectionTapped(collectible)
                    }
                )
                .ignoresSafeArea()
            } else {
                // 非AR模式：使用地图 + 收集点叠加
                ZStack {
                    // 背景地图
                    MapViewWithCollectibles(
                        region: $region,
                        route: route.route,
                        startCoordinate: $startCoordinate,
                        endCoordinate: $endCoordinate,
                        userLocation: $userLocation,
                        collectibles: collectiblesInRange,
                        onCollectibleTapped: { collectible in
                            print("🎯 DEBUG: 地图点击收集点: \(collectible.name)")
                            selectedCollectible = collectible
                            showingCollectiblePopup = true
                        }
                    )
                    
                    // 导航指令悬浮窗
                    if let instruction = currentInstruction {
                        VStack {
                            NavigationInstructionOverlay(instruction: instruction)
                                .padding(.top, 120)
                            Spacer()
                        }
                    }
                }
            }
            
            // UI叠加层
            VStack {
                // 顶部状态栏
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.white.opacity(0.8))
                            Text(remainingTime)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .font(.callout)
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.white.opacity(0.8))
                            Text(remainingDistance)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .font(.callout)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // 收集统计按钮
                        Button(action: {
                            print("🎯 DEBUG: 点击收集统计按钮")
                            showingCollection = true
                        }) {
                            HStack {
                                Image(systemName: "bag")
                                    .foregroundColor(.white)
                                Text("\(collectionManager.getCollectionStats().total)")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        HStack {
                            Image(systemName: useARMode ? "arkit" : "map")
                                .foregroundColor(useARMode ? .blue : .green)
                            Text(useARMode ? "AR导航" : "地图导航")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                Spacer()
                
                // 中间区域：收集点距离指示器
                if !collectiblesInRange.isEmpty {
                    VStack {
                        CollectibleDistanceIndicator(
                            collectibles: collectiblesInRange,
                            userLocation: userLocation
                        )
                        .padding(.horizontal)
                        
                        // 显示范围内收集点数量
                        Text("附近有 \(collectiblesInRange.count) 个收集点")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Debug信息显示
                if !debugInfo.isEmpty {
                    Text(debugInfo)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal)
                }
                
                // 底部控制栏
                HStack(spacing: 20) {
                    // 返回按钮
                    Button(action: {
                        print("🎯 DEBUG: 点击返回按钮")
                        onBackTapped()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red, lineWidth: 2)
                                    )
                            )
                    }
                    
                    // AR/地图切换按钮
                    Button(action: {
                        print("🎯 DEBUG: 切换AR/地图模式: \(useARMode ? "地图" : "AR")")
                        withAnimation(.spring()) {
                            useARMode.toggle()
                        }
                        updateDebugInfo()
                    }) {
                        Image(systemName: useARMode ? "map" : "arkit")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            )
                    }
                    
                    // 播放/暂停
                    Button(action: {
                        print("🎯 DEBUG: 点击播放/暂停按钮: \(isNavigating ? "暂停" : "播放")")
                        withAnimation(.spring()) {
                            isNavigating.toggle()
                        }
                        
                        if isNavigating {
                            startNavigationTimer()
                        } else {
                            stopNavigationTimer()
                        }
                        updateDebugInfo()
                    }) {
                        Image(systemName: isNavigating ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(
                                Circle()
                                    .fill(isNavigating ? Color.orange : Color.green)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                    )
                            )
                    }
                    
                    // 收集页面按钮
                    Button(action: {
                        print("🎯 DEBUG: 点击收集页面按钮")
                        showingCollection = true
                    }) {
                        Image(systemName: "bag.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            )
                    }
                    
                    // Debug按钮
                    Button(action: {
                        print("🎯 DEBUG: 手动触发收集点生成")
                        setupCollectionManager()
                        updateDebugInfo()
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray, lineWidth: 2)
                                    )
                            )
                    }
                }
                .padding(.bottom, 50)
            }
            
            // 收集成功提示
            if showingCollectionSuccess {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        Text("收集成功：\(lastCollectedItem)")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.bottom, 200)
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingCollection) {
            CollectionView(collectionManager: collectionManager)
        }
        .sheet(isPresented: $showingCollectiblePopup) {
            if let collectible = selectedCollectible {
                CollectibleInfoSheet(
                    collectible: collectible,
                    onCollect: {
                        handleCollectionTapped(collectible)
                        showingCollectiblePopup = false
                    },
                    onDismiss: {
                        showingCollectiblePopup = false
                    }
                )
                .presentationDetents([.height(300)])
            }
        }
        .onAppear {
            print("🎯 DEBUG: EnhancedARNavigationView onAppear")
            setupCollectionManager()
            updateNavigationInfo()
            updateUserLocation()
            updateDebugInfo()
        }
        .onDisappear {
            print("🎯 DEBUG: EnhancedARNavigationView onDisappear")
            stopNavigationTimer()
        }
    }
    
    // MARK: - 收集功能实现
    
    private func setupCollectionManager() {
        print("🎯 DEBUG: setupCollectionManager 开始")
        print("  🎯 路线类型: \(route.specialRouteType.rawValue)")
        print("  🎯 指令数量: \(route.instructions.count)")
        
        // 生成收集点
        collectionManager.generateCollectiblePoints(for: route.specialRouteType, instructions: route.instructions)
        
        print("  🎯 生成的收集点数量: \(collectionManager.availableCollectibles.count)")
        for (index, collectible) in collectionManager.availableCollectibles.enumerated() {
            print("    \(index + 1). \(collectible.name) (\(collectible.category.rawValue)) - 已收集: \(collectible.isCollected)")
        }
    }
    
    private func updateUserLocation() {
        // 模拟用户位置更新
        if let currentInstruction = currentInstruction {
            userLocation = currentInstruction.coordinate
            collectionManager.updateLocation(currentInstruction.coordinate)
            
            print("🎯 DEBUG: 用户位置更新")
            print("  📍 坐标: (\(currentInstruction.coordinate.latitude), \(currentInstruction.coordinate.longitude))")
            print("  🎯 范围内收集点: \(collectiblesInRange.count)个")
        }
    }
    
    private func handleCollectionTapped(_ collectible: CollectiblePoint) {
        print("🎯 DEBUG: handleCollectionTapped 开始")
        print("  🎯 收集点: \(collectible.name)")
        print("  🎯 类别: \(collectible.category.rawValue)")
        print("  🎯 已收集: \(collectible.isCollected)")
        
        if collectible.isCollected {
            print("  ⚠️ 物品已收集，跳过")
            return
        }
        
        // 执行收集
        collectionManager.collectItem(collectible, routeType: route.specialRouteType)
        
        // 显示收集成功提示
        lastCollectedItem = collectible.name
        withAnimation(.easeInOut(duration: 0.3)) {
            showingCollectionSuccess = true
        }
        
        print("  ✅ 收集成功提示显示")
        
        // 3秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCollectionSuccess = false
            }
        }
        
        // 更新debug信息
        updateDebugInfo()
    }
    
    // MARK: - 定时器和状态更新
    
    private func startNavigationTimer() {
        print("🎯 DEBUG: 开始导航定时器")
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            currentSpeed = String(Int.random(in: 20...60))
            updateNavigationInfo()
            updateUserLocation()
            updateDebugInfo()
            
            // 自动推进导航
            if isNavigating && Int.random(in: 1...3) == 1 {
                if currentLocationIndex < route.instructions.count - 1 {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        currentLocationIndex += 1
                    }
                    print("🎯 DEBUG: 自动推进到指令 \(currentLocationIndex + 1)")
                }
            }
        }
    }
    
    private func stopNavigationTimer() {
        print("🎯 DEBUG: 停止导航定时器")
        timer?.invalidate()
        timer = nil
    }
    
    private func updateNavigationInfo() {
        let remaining = route.instructions.count - currentLocationIndex
        remainingTime = "\(remaining * 2)分钟"
        remainingDistance = String(format: "%.1f公里", Double(remaining) * 0.3)
    }
    
    private func updateDebugInfo() {
        let stats = collectionManager.getCollectionStats()
        debugInfo = "位置:\(currentLocationIndex+1)/\(route.instructions.count) | 收集:\(stats.total) | 附近:\(collectiblesInRange.count) | 模式:\(useARMode ? "AR" : "地图")"
    }
}

// MARK: - 辅助视图

// 导航指令悬浮窗
struct NavigationInstructionOverlay: View {
    let instruction: NavigationInstruction
    
    var body: some View {
        HStack {
            Image(systemName: instruction.icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(instruction.instruction)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("在 \(instruction.distance) 处")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

// 带收集点的地图视图
struct MapViewWithCollectibles: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: MKRoute?
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @Binding var userLocation: CLLocationCoordinate2D?
    let collectibles: [CollectiblePoint]
    let onCollectibleTapped: (CollectiblePoint) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        // 添加手势识别器
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 清除旧的注释
        let oldAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
        uiView.removeAnnotations(oldAnnotations)
        
        // 清除旧的覆盖层
        uiView.removeOverlays(uiView.overlays)
        
        // 添加起点和终点
        if let start = startCoordinate {
            let startAnnotation = CollectibleAnnotation(
                coordinate: start,
                title: "起点",
                subtitle: "",
                collectible: nil
            )
            uiView.addAnnotation(startAnnotation)
        }
        
        if let end = endCoordinate {
            let endAnnotation = CollectibleAnnotation(
                coordinate: end,
                title: "终点",
                subtitle: "",
                collectible: nil
            )
            uiView.addAnnotation(endAnnotation)
        }
        
        // 添加路线
        if let route = route {
            uiView.addOverlay(route.polyline)
        }
        
        // 添加收集点注释
        for collectible in collectibles {
            let annotation = CollectibleAnnotation(
                coordinate: collectible.coordinate,
                title: collectible.name,
                subtitle: collectible.category.rawValue,
                collectible: collectible
            )
            uiView.addAnnotation(annotation)
        }
        
        // 更新coordinator的回调
        context.coordinator.onCollectibleTapped = onCollectibleTapped
        
        print("🎯 DEBUG: 地图更新完成，添加了\(collectibles.count)个收集点注释")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var onCollectibleTapped: ((CollectiblePoint) -> Void)?
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 8
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            guard let collectibleAnnotation = annotation as? CollectibleAnnotation else {
                return nil
            }
            
            let identifier = "CollectibleAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                if let collectible = collectibleAnnotation.collectible {
                    // 收集点样式
                    markerView.markerTintColor = getUIColorForCategory(collectible.category)
                    markerView.glyphText = getEmojiForCategory(collectible.category)
                    markerView.alpha = collectible.isCollected ? 0.5 : 1.0
                } else if collectibleAnnotation.title == "起点" {
                    markerView.markerTintColor = .systemGreen
                    markerView.glyphText = "🚀"
                } else if collectibleAnnotation.title == "终点" {
                    markerView.markerTintColor = .systemRed
                    markerView.glyphText = "🏁"
                }
            }
            
            return annotationView
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            // 查找最近的收集点注释
            let annotations = mapView.annotations.compactMap { $0 as? CollectibleAnnotation }
            
            for annotation in annotations {
                if let collectible = annotation.collectible {
                    let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
                    let distance = sqrt(pow(location.x - annotationPoint.x, 2) + pow(location.y - annotationPoint.y, 2))
                    
                    if distance < 44 { // 44点的点击区域
                        print("🎯 DEBUG: 地图点击收集点: \(collectible.name)")
                        onCollectibleTapped?(collectible)
                        break
                    }
                }
            }
        }
        
        private func getUIColorForCategory(_ category: CollectibleCategory) -> UIColor {
            switch category.color {
            case "orange": return .systemOrange
            case "green": return .systemGreen
            case "blue": return .systemBlue
            case "purple": return .systemPurple
            case "red": return .systemRed
            default: return .systemGray
            }
        }
        
        private func getEmojiForCategory(_ category: CollectibleCategory) -> String {
            switch category {
            case .food: return "🍜"
            case .scenic: return "🏔️"
            case .attraction: return "📸"
            case .landmark: return "🏛️"
            case .culture: return "🎭"
            }
        }
    }
}

// 收集点注释类
class CollectibleAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let collectible: CollectiblePoint?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, collectible: CollectiblePoint?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.collectible = collectible
        super.init()
    }
}

// 收集点信息弹窗
struct CollectibleInfoSheet: View {
    let collectible: CollectiblePoint
    let onCollect: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部图标和名称
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(colorForCategory(collectible.category).opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: collectible.category.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(colorForCategory(collectible.category))
                }
                
                Text(collectible.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(collectible.category.rawValue)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorForCategory(collectible.category).opacity(0.2))
                    )
                    .foregroundColor(colorForCategory(collectible.category))
            }
            
            // 描述
            Text(collectible.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // 按钮
            HStack(spacing: 20) {
                Button("取消") {
                    onDismiss()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary, lineWidth: 1)
                )
                
                Button(collectible.isCollected ? "已收集" : "收集") {
                    if !collectible.isCollected {
                        onCollect()
                    } else {
                        onDismiss()
                    }
                }
                .disabled(collectible.isCollected)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(collectible.isCollected ? Color.gray : colorForCategory(collectible.category))
                )
            }
        }
        .padding()
    }
    
    private func colorForCategory(_ category: CollectibleCategory) -> Color {
        switch category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

#Preview {
    // 预览代码
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CollectibleItem.self, configurations: config)
    let context = container.mainContext
    let manager = CollectionManager(modelContext: context)
    
    let sampleRoute = RouteInfo(
        type: .fastest,
        transportType: .walking,
        distance: "2.5公里",
        duration: "30分钟",
        price: "",
        route: nil,
        description: "风景路线",
        instructions: [
            NavigationInstruction(instruction: "开始导航", distance: "0m", icon: "location.fill", coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074))
        ],
        specialRouteType: .scenic,
        highlights: ["风景优美"],
        difficulty: .easy
    )
    
    EnhancedARNavigationView(
        route: sampleRoute,
        currentLocationIndex: .constant(0),
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )),
        startCoordinate: .constant(CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)),
        endCoordinate: .constant(CLLocationCoordinate2D(latitude: 39.9142, longitude: 116.4174)),
        collectionManager: manager,
        onBackTapped: {}
    )
    .modelContainer(container)
}
