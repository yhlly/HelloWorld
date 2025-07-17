//
//  ContentView.swift
//  HelloWorld
//
//  Created by haliluye on 2025/6/20.
//

import SwiftUI
import MapKit
import ARKit
import RealityKit

// 页面状态枚举
enum AppState {
    case search
    case routePreview
    case threeDMap
    case arMap
}

// 交通方式枚举
enum TransportationType: String, CaseIterable {
    case walking = "步行"
    case driving = "驾车"
    case publicTransport = "公交"
    
    var icon: String {
        switch self {
        case .walking:
            return "figure.walk"
        case .driving:
            return "car.fill"
        case .publicTransport:
            return "bus.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .walking:
            return .green
        case .driving:
            return .blue
        case .publicTransport:
            return .orange
        }
    }
    
    var mkDirectionsTransportType: MKDirectionsTransportType {
        switch self {
        case .walking:
            return .walking
        case .driving:
            return .automobile
        case .publicTransport:
            return .transit
        }
    }
}

// 路线类型枚举
enum RouteType: String, CaseIterable {
    case fastest = "最快路线"
    case shortest = "最短路线"
    case cheapest = "最省钱"
    case scenic = "风景路线"
    
    var icon: String {
        switch self {
        case .fastest:
            return "clock.fill"
        case .shortest:
            return "arrow.right"
        case .cheapest:
            return "yensign.circle.fill"
        case .scenic:
            return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .fastest:
            return .red
        case .shortest:
            return .blue
        case .cheapest:
            return .green
        case .scenic:
            return .purple
        }
    }
}

// 路线信息数据结构
struct RouteInfo {
    let id = UUID()
    let type: RouteType
    let transportType: TransportationType
    let distance: String
    let duration: String
    let price: String
    let route: MKRoute?
    let description: String
}

// 地点搜索框组件
struct LocationSearchBar: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let onCommit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text, onCommit: onCommit)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// 交通方式选择按钮
struct TransportTab: View {
    let type: TransportationType
    let isSelected: Bool
    let routeCount: Int
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isEnabled ? (isSelected ? type.color : .gray) : .gray.opacity(0.5))
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(isEnabled ? (isSelected ? type.color : .gray) : .gray.opacity(0.5))
                
                if routeCount > 0 {
                    Text("\(routeCount)条路线")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if !isEnabled {
                    Text("暂不支持")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isEnabled && isSelected ? type.color.opacity(0.1) : Color.clear
            )
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

// 路线卡片组件
struct RouteCard: View {
    let route: RouteInfo
    let onGoTapped: () -> Void
    
    var body: some View {
        HStack {
            // 左侧图标和类型
            VStack {
                Image(systemName: route.type.icon)
                    .foregroundColor(route.type.color)
                    .font(.title2)
                Text(route.type.rawValue)
                    .font(.caption)
                    .foregroundColor(route.type.color)
            }
            .frame(width: 70)
            
            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(route.duration)
                        .font(.headline)
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                    Text(route.distance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !route.price.isEmpty {
                    HStack {
                        Image(systemName: "yensign.circle")
                            .foregroundColor(.secondary)
                        Text(route.price)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(route.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 右侧GO按钮
            Button(action: onGoTapped) {
                Text("GO")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 35)
                    .background(route.route != nil ? Color.green : Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 普通地图视图
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: MKRoute?
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        
        // 确保地图交互正常
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 移除之前的路线和标注
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        // 验证并添加起点标注
        if let start = startCoordinate, CLLocationCoordinate2DIsValid(start) {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            uiView.addAnnotation(startAnnotation)
        }
        
        // 验证并添加终点标注
        if let end = endCoordinate, CLLocationCoordinate2DIsValid(end) {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "终点"
            uiView.addAnnotation(endAnnotation)
        }
        
        // 添加路线
        if let route = route {
            uiView.addOverlay(route.polyline)
            
            // 调整地图显示范围
            let rect = route.polyline.boundingMapRect
            uiView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        } else if let start = startCoordinate, let end = endCoordinate,
                  CLLocationCoordinate2DIsValid(start), CLLocationCoordinate2DIsValid(end) {
            // 没有路线时，调整地图显示起终点
            let centerLatitude = (start.latitude + end.latitude) / 2
            let centerLongitude = (start.longitude + end.longitude) / 2
            
            // 计算合适的显示范围
            let latitudeDelta = max(abs(start.latitude - end.latitude) * 1.5, 0.01)
            let longitudeDelta = max(abs(start.longitude - end.longitude) * 1.5, 0.01)
            
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
            uiView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

// 3D地图视图
struct ThreeDMapView: UIViewRepresentable {
    let route: MKRoute?
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = .hybridFlyover // 3D卫星地图
        mapView.showsBuildings = true
        mapView.showsTraffic = true
        
        // 确保3D地图能正确加载
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        // 设置初始区域为北京
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        mapView.setRegion(initialRegion, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 移除之前的路线和标注
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        // 验证并添加起点和终点标注
        if let start = startCoordinate, CLLocationCoordinate2DIsValid(start) {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            uiView.addAnnotation(startAnnotation)
        }
        
        if let end = endCoordinate, CLLocationCoordinate2DIsValid(end) {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "终点"
            uiView.addAnnotation(endAnnotation)
        }
        
        // 添加路线
        if let route = route {
            uiView.addOverlay(route.polyline)
            
            // 正确设置3D视角 - 转换MKMapRect到经纬度坐标
            let rect = route.polyline.boundingMapRect
            let centerMapPoint = MKMapPoint(x: rect.midX, y: rect.midY)
            let center = centerMapPoint.coordinate
            
            // 验证坐标有效性
            if CLLocationCoordinate2DIsValid(center) {
                // 计算合适的相机高度基于路线范围
                let distance = max(rect.size.width, rect.size.height)
                let altitude = max(distance * 0.5, 500) // 最小高度500米
                
                // 创建3D相机视角
                let camera = MKMapCamera()
                camera.centerCoordinate = center
                camera.altitude = altitude
                camera.pitch = 60 // 俯仰角
                camera.heading = 0 // 方向角
                
                uiView.setCamera(camera, animated: true)
            }
        } else if let start = startCoordinate, let end = endCoordinate,
                  CLLocationCoordinate2DIsValid(start), CLLocationCoordinate2DIsValid(end) {
            // 没有路线时，设置3D视角显示起终点
            let centerLatitude = (start.latitude + end.latitude) / 2
            let centerLongitude = (start.longitude + end.longitude) / 2
            let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
            
            // 根据起终点距离计算相机高度
            let latDistance = abs(start.latitude - end.latitude)
            let lonDistance = abs(start.longitude - end.longitude)
            let maxDistance = max(latDistance, lonDistance)
            let altitude = max(maxDistance * 111000 * 2, 1000) // 转换为米并设置最小高度
            
            let camera = MKMapCamera()
            camera.centerCoordinate = center
            camera.altitude = altitude
            camera.pitch = 45
            camera.heading = 0
            
            uiView.setCamera(camera, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ThreeDMapView
        
        init(_ parent: ThreeDMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemRed
                renderer.lineWidth = 8
                renderer.alpha = 0.8
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

// AR导航视图
struct ARNavigationView: UIViewRepresentable {
    let route: MKRoute?
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    @Binding var isARSupported: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // 检查AR支持
        if !ARWorldTrackingConfiguration.isSupported {
            isARSupported = false
            return arView
        }
        
        isARSupported = true
        
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.worldAlignment = .gravityAndHeading
        
        arView.session.run(configuration)
        
        // 添加AR内容
        setupARContent(arView: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // 更新AR内容
    }
    
    private func setupARContent(arView: ARView) {
        // 创建一个简单的AR导航指示器
        let anchorEntity = AnchorEntity(world: SIMD3<Float>(0, 0, -1))
        
        // 创建一个箭头指示器
        let arrowMesh = MeshResource.generateBox(size: SIMD3<Float>(0.1, 0.02, 0.3))
        let arrowMaterial = SimpleMaterial(color: .systemBlue, isMetallic: false)
        let arrowEntity = ModelEntity(mesh: arrowMesh, materials: [arrowMaterial])
        
        // 添加文本指示
        let textMesh = MeshResource.generateText(
            "导航中...",
            extrusionDepth: 0.02,
            font: .systemFont(ofSize: 0.1),
            containerFrame: CGRect.zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.transform.translation.y = 0.2
        
        anchorEntity.addChild(arrowEntity)
        anchorEntity.addChild(textEntity)
        arView.scene.addAnchor(anchorEntity)
        
        // 添加简单的动画
        let rotateAction = Transform(rotation: simd_quatf(angle: .pi * 2, axis: SIMD3<Float>(0, 1, 0)))
        let animationResource = try! AnimationResource.generate(with: FromToByAnimation(
            to: rotateAction,
            duration: 2.0,
            bindTarget: .transform
        ))
        
        arrowEntity.playAnimation(animationResource.repeat())
    }
}

// 主视图
struct ContentView: View {
    @State private var currentState: AppState = .search
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var selectedTransportType: TransportationType = .driving
    @State private var routes: [TransportationType: [RouteInfo]] = [:]
    @State private var selectedRoute: RouteInfo?
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage = ""
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var isARSupported = true
    
    var body: some View {
        NavigationView {
            switch currentState {
            case .search:
                searchAndRouteView
            case .routePreview:
                routePreviewView
            case .threeDMap:
                threeDMapView
            case .arMap:
                arNavigationView
            }
        }
    }
    
    // 搜索和路线选择界面
    private var searchAndRouteView: some View {
        VStack(spacing: 0) {
            // 顶部搜索区域
            VStack(spacing: 20) {
                Text("路线规划")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 地点输入区域
                VStack(spacing: 15) {
                    LocationSearchBar(
                        placeholder: "起点",
                        text: $startLocation,
                        icon: "location.circle"
                    ) {
                        checkAndSearch()
                    }
                    
                    // 交换按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            let temp = startLocation
                            startLocation = endLocation
                            endLocation = temp
                            checkAndSearch()
                        }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        Spacer()
                    }
                    
                    LocationSearchBar(
                        placeholder: "终点",
                        text: $endLocation,
                        icon: "location.fill"
                    ) {
                        checkAndSearch()
                    }
                }
                .padding(.horizontal)
                
                // 搜索按钮（在输入地点后显示）
                if !startLocation.isEmpty && !endLocation.isEmpty && !hasSearched {
                    Button(action: {
                        searchAllRoutes()
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
                        .padding()
                        .background(isSearching ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isSearching)
                    .padding(.horizontal)
                }
                
                // 错误信息
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .font(.caption)
                }
            }
            .background(Color(.systemBackground))
            
            // 路线选择区域（搜索后显示）
            if hasSearched && !routes.isEmpty {
                VStack(spacing: 0) {
                    // 分隔线
                    Divider()
                        .padding(.vertical, 10)
                    
                    // 交通方式选择标签
                    HStack(spacing: 0) {
                        ForEach(TransportationType.allCases, id: \.self) { type in
                            TransportTab(
                                type: type,
                                isSelected: selectedTransportType == type,
                                routeCount: routes[type]?.count ?? 0,
                                isEnabled: true
                            ) {
                                selectedTransportType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // 路线列表
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if let routeList = routes[selectedTransportType], !routeList.isEmpty {
                                ForEach(routeList, id: \.id) { route in
                                    RouteCard(route: route) {
                                        selectedRoute = route
                                        currentState = .routePreview
                                    }
                                }
                            } else {
                                VStack {
                                    Image(systemName: selectedTransportType.icon)
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("正在为您查找\(selectedTransportType.rawValue)路线...")
                                        .foregroundColor(.secondary)
                                    if selectedTransportType == .publicTransport {
                                        Text("包括地铁、公交、BRT等多种选择")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
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
                    Text("请检查起终点地址是否正确")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else if !hasSearched {
                Spacer()
            }
        }
    }
    
    // 路线预览界面
    private var routePreviewView: some View {
        VStack(spacing: 0) {
            // 顶部信息栏
            HStack {
                Button("返回") {
                    currentState = .search
                }
                
                Spacer()
                
                if let route = selectedRoute {
                    VStack {
                        Text(route.type.rawValue)
                            .font(.headline)
                        HStack {
                            Image(systemName: route.transportType.icon)
                            Text(route.duration)
                            Text(route.distance)
                            if !route.price.isEmpty {
                                Text(route.price)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 新增的Preview和Play按钮
                HStack(spacing: 12) {
                    Button("Preview") {
                        currentState = .threeDMap
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple)
                    .cornerRadius(8)
                    
                    Button("Play") {
                        currentState = .arMap
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 地图
            if selectedRoute?.route != nil {
                MapViewRepresentable(
                    region: $region,
                    route: selectedRoute?.route,
                    startCoordinate: $startCoordinate,
                    endCoordinate: $endCoordinate
                )
            } else {
                // 没有实际路线时显示起终点的简单地图
                VStack {
                    MapViewRepresentable(
                        region: $region,
                        route: nil,
                        startCoordinate: $startCoordinate,
                        endCoordinate: $endCoordinate
                    )
                    
                    VStack {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("公共交通路线预览")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        Text("点击Preview查看3D地图，点击Play体验AR导航")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()
                }
            }
        }
    }
    
    // 3D地图预览界面
    private var threeDMapView: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Button("返回") {
                    currentState = .routePreview
                }
                
                Spacer()
                
                Text("3D路线预览")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("AR导航") {
                    currentState = .arMap
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 3D地图
            ThreeDMapView(
                route: selectedRoute?.route,
                startCoordinate: startCoordinate,
                endCoordinate: endCoordinate
            )
            .overlay(
                // 3D地图控制提示
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("3D地图操作:")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("• 双指捏合：缩放")
                                .font(.caption2)
                            Text("• 单指拖拽：平移")
                                .font(.caption2)
                            Text("• 双指旋转：旋转视角")
                                .font(.caption2)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        Spacer()
                    }
                    .padding()
                }
            )
        }
    }
    
    // AR导航界面
    private var arNavigationView: some View {
        VStack(spacing: 0) {
            if !isARSupported {
                // AR不支持时的提示界面
                VStack {
                    HStack {
                        Button("返回") {
                            currentState = .routePreview
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("AR功能不可用")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("您的设备不支持AR功能，或者应用没有相机权限")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("返回3D预览") {
                            currentState = .threeDMap
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                    
                    Spacer()
                }
            } else {
                // AR支持时的界面
                VStack {
                    // AR顶部工具栏
                    HStack {
                        Button("退出AR") {
                            currentState = .routePreview
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        VStack {
                            Text("AR实景导航")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if let route = selectedRoute {
                                Text("\(route.duration) • \(route.distance)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button("3D") {
                            currentState = .threeDMap
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.clear)
                    .zIndex(1)
                    
                    // AR视图
                    ARNavigationView(
                        route: selectedRoute?.route,
                        startCoordinate: startCoordinate,
                        endCoordinate: endCoordinate,
                        isARSupported: $isARSupported
                    )
                    .overlay(
                        // AR导航指示器
                        VStack {
                            Spacer()
                            
                            // 底部导航信息
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "arrow.up")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text("直行 500米")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("然后右转")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack {
                                        Text("2.3km")
                                            .font(.caption)
                                        Text("剩余")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                            }
                            .padding()
                        }
                    )
                }
            }
        }
    }
    
    // 检查并自动搜索
    func checkAndSearch() {
        if !startLocation.isEmpty && !endLocation.isEmpty && !hasSearched {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.startLocation.isEmpty && !self.endLocation.isEmpty {
                    self.searchAllRoutes()
                }
            }
        }
    }
    
    // 搜索所有路线
    func searchAllRoutes() {
        guard !startLocation.isEmpty && !endLocation.isEmpty else { return }
        
        isSearching = true
        errorMessage = ""
        routes.removeAll()
        hasSearched = false
        
        // 地理编码
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(startLocation) { startPlacemarks, startError in
            guard let startPlacemark = startPlacemarks?.first,
                  let startLoc = startPlacemark.location else {
                DispatchQueue.main.async {
                    self.errorMessage = "无法找到起点地址"
                    self.isSearching = false
                }
                return
            }
            
            geocoder.geocodeAddressString(self.endLocation) { endPlacemarks, endError in
                guard let endPlacemark = endPlacemarks?.first,
                      let endLoc = endPlacemark.location else {
                    DispatchQueue.main.async {
                        self.errorMessage = "无法找到终点地址"
                        self.isSearching = false
                    }
                    return
                }
                
                self.startCoordinate = startLoc.coordinate
                self.endCoordinate = endLoc.coordinate
                
                // 为每种交通方式计算路线
                self.calculateRoutesForAllTransportTypes(from: startLoc.coordinate, to: endLoc.coordinate)
            }
        }
    }
    
    // 为所有交通方式计算路线
    func calculateRoutesForAllTransportTypes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let group = DispatchGroup()
        
        for transportType in TransportationType.allCases {
            group.enter()
            calculateRoute(from: start, to: end, transportType: transportType) { routeInfos in
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
    
    // 计算特定交通方式的路线
    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, completion: @escaping ([RouteInfo]) -> Void) {
        if transportType == .publicTransport {
            // 特殊处理公共交通
            calculatePublicTransportRoute(from: start, to: end, completion: completion)
        } else {
            // 步行和驾车使用标准MapKit
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
            request.transportType = transportType.mkDirectionsTransportType
            request.requestsAlternateRoutes = true
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let response = response, !response.routes.isEmpty else {
                    completion([])
                    return
                }
                
                var routeInfos: [RouteInfo] = []
                
                for (index, route) in response.routes.enumerated() {
                    let distance = String(format: "%.1f公里", route.distance / 1000)
                    let duration = String(format: "%.0f分钟", route.expectedTravelTime / 60)
                    
                    let routeType: RouteType
                    let price: String
                    let description: String
                    
                    switch index {
                    case 0:
                        routeType = .fastest
                        price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.8))" : ""
                        description = "推荐路线，路况较好，用时最短"
                    case 1:
                        routeType = .shortest
                        price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.7))" : ""
                        description = "距离最短，可能有拥堵"
                    case 2:
                        routeType = .cheapest
                        price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.6))" : ""
                        description = "经济路线，费用最低"
                    default:
                        routeType = .scenic
                        price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.9))" : ""
                        description = "风景路线，沿途景色优美"
                    }
                    
                    let routeInfo = RouteInfo(
                        type: routeType,
                        transportType: transportType,
                        distance: distance,
                        duration: duration,
                        price: price,
                        route: route,
                        description: description
                    )
                    
                    routeInfos.append(routeInfo)
                }
                
                completion(routeInfos)
            }
        }
    }
    
    // 专门处理公共交通路线
    func calculatePublicTransportRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping ([RouteInfo]) -> Void) {
        // 首先尝试MapKit的公共交通
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .transit
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let response = response, !response.routes.isEmpty {
                // MapKit找到了公共交通路线
                var routeInfos: [RouteInfo] = []
                
                for (index, route) in response.routes.enumerated() {
                    let distance = String(format: "%.1f公里", route.distance / 1000)
                    let duration = String(format: "%.0f分钟", route.expectedTravelTime / 60)
                    
                    let routeType: RouteType
                    let price: String
                    let description: String
                    
                    switch index {
                    case 0:
                        routeType = .fastest
                        price = "¥3-6"
                        description = "最快公交路线，换乘较少"
                    case 1:
                        routeType = .cheapest
                        price = "¥2-4"
                        description = "经济公交路线，票价较低"
                    default:
                        routeType = .shortest
                        price = "¥3-5"
                        description = "较短公交路线，距离较近"
                    }
                    
                    let routeInfo = RouteInfo(
                        type: routeType,
                        transportType: .publicTransport,
                        distance: distance,
                        duration: duration,
                        price: price,
                        route: route,
                        description: description
                    )
                    
                    routeInfos.append(routeInfo)
                }
                
                completion(routeInfos)
            } else {
                // MapKit没找到，提供模拟的公共交通路线
                self.generateSimulatedPublicTransportRoutes(from: start, to: end, completion: completion)
            }
        }
    }
    
    // 生成模拟的公共交通路线（当MapKit不支持时）
    func generateSimulatedPublicTransportRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping ([RouteInfo]) -> Void) {
        // 计算直线距离来估算公交路线
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        
        let distanceKm = distance / 1000
        
        // 根据距离估算时间和价格
        let baseTime = max(distanceKm * 3, 15) // 公交比驾车慢，最少15分钟
        let basePrice = max(Int(distanceKm * 0.5 + 2), 2) // 基础票价
        
        var routeInfos: [RouteInfo] = []
        
        // 地铁+公交组合路线
        if distanceKm > 3 {
            let subwayRoute = RouteInfo(
                type: .fastest,
                transportType: .publicTransport,
                distance: String(format: "%.1f公里", distanceKm),
                duration: String(format: "%.0f分钟", baseTime),
                price: "¥\(basePrice + 1)-\(basePrice + 3)",
                route: nil,
                description: "地铁 + 公交组合，换乘1-2次，较快到达"
            )
            routeInfos.append(subwayRoute)
        }
        
        // 纯公交路线
        let busRoute = RouteInfo(
            type: .cheapest,
            transportType: .publicTransport,
            distance: String(format: "%.1f公里", distanceKm * 1.2), // 公交路线通常更长
            duration: String(format: "%.0f分钟", baseTime * 1.3),
            price: "¥\(basePrice)-\(basePrice + 1)",
            route: nil,
            description: "纯公交路线，换乘较少，价格便宜"
        )
        routeInfos.append(busRoute)
        
        // 快速公交路线
        if distanceKm > 5 {
            let rapidBusRoute = RouteInfo(
                type: .scenic,
                transportType: .publicTransport,
                distance: String(format: "%.1f公里", distanceKm * 1.1),
                duration: String(format: "%.0f分钟", baseTime * 0.9),
                price: "¥\(basePrice + 2)-\(basePrice + 4)",
                route: nil,
                description: "快速公交(BRT)，站点较少，速度较快"
            )
            routeInfos.append(rapidBusRoute)
        }
        
        // 如果距离很短，提供短途公交
        if distanceKm <= 3 {
            let shortBusRoute = RouteInfo(
                type: .shortest,
                transportType: .publicTransport,
                distance: String(format: "%.1f公里", distanceKm),
                duration: String(format: "%.0f分钟", max(baseTime, 20)),
                price: "¥2-3",
                route: nil,
                description: "短途公交，直达或换乘1次"
            )
            routeInfos.append(shortBusRoute)
        }
        
        completion(routeInfos)
    }
}

#Preview {
    ContentView()
}
