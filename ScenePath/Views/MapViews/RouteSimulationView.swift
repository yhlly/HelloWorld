//
//  RouteSimulationView.swift
//  ScenePath
//
//  路线模拟视图 - 简化版本
//

import SwiftUI
import MapKit
import CoreLocation

struct RouteSimulationView: View {
    let route: RouteInfo
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    
    let onBackTapped: () -> Void
    let onStartRealNavigation: () -> Void
    
    // 路线播放器
    @StateObject private var simulationPlayer = RouteSimulationPlayer()
    
    // 状态变量
    @State private var avatarLocation: CLLocationCoordinate2D?
    @State private var avatarHeading: Double = 0
    @State private var totalDistance: String = ""
    @State private var totalTime: String = ""
    @State private var completionPercentage: Double = 0.0
    @State private var nearbyPOI: String? = nil
    @State private var showInfoPopup: Bool = false
    
    // 显示设置
    @State private var showMap3D: Bool = true
    @State private var cameraFollowsAvatar: Bool = true
    
    // 获取交通方式图标和名称
    private var transportIcon: String {
        return route.transportType.simulationIcon
    }
    
    private var transportName: String {
        return route.transportType.rawValue
    }
    
    var body: some View {
        ZStack {
            // 3D地图或2D地图
            if showMap3D {
                SimulationMap3DView(
                    route: route.route,
                    startCoordinate: startCoordinate,
                    endCoordinate: endCoordinate,
                    avatarLocation: avatarLocation,
                    avatarHeading: avatarHeading,
                    followsAvatar: cameraFollowsAvatar,
                    transportType: route.transportType
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                SimulationMapView(
                    route: route.route,
                    startCoordinate: startCoordinate,
                    endCoordinate: endCoordinate,
                    avatarLocation: avatarLocation,
                    avatarHeading: avatarHeading,
                    followsAvatar: cameraFollowsAvatar,
                    transportType: route.transportType
                )
                .edgesIgnoringSafeArea(.all)
            }
            
            // UI层
            VStack {
                // 顶部状态栏
                HStack {
                    // 返回按钮
                    Button(action: {
                        // 停止播放并返回
                        simulationPlayer.stopPlaying()
                        onBackTapped()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    
                    Spacer()
                    
                    // 标题和路线信息
                    VStack(spacing: 4) {
                        Text("\(transportName)路线模拟")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Label("\(Int(completionPercentage * 100))%", systemImage: "arrowtriangle.right.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.6)))
                    
                    Spacer()
                    
                    // 模式切换按钮
                    Button(action: {
                        withAnimation {
                            showMap3D.toggle()
                        }
                    }) {
                        Image(systemName: showMap3D ? "map" : "view.3d")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                }
                .padding()
                
                Spacer()
                
                // 进度信息卡片
                VStack(spacing: 10) {
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 8)
                            
                            // 进度
                            RoundedRectangle(cornerRadius: 4)
                                .fill(route.transportType.color)
                                .frame(width: max(0, geometry.size.width * CGFloat(completionPercentage)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    // 详细信息
                    HStack {
                        // 距离信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text("总距离")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(totalDistance)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // 时间信息
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("总时间")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(totalTime)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.6)))
                .padding(.horizontal)
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 20) {
                    // 路线播放控制器
                    RoutePlayerControls(player: simulationPlayer)
                        .padding(.horizontal)
                    
                    // 开始实际导航按钮
                    Button(action: {
                        simulationPlayer.stopPlaying()
                        onStartRealNavigation()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("开始实际导航")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue)
                        )
                    }
                }
                .padding(.bottom, 30)
                .background(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .edgesIgnoringSafeArea(.bottom)
                )
            }
            
            // 弹出信息 (当用户移动到特定点位)
            if showInfoPopup {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    Text(nearbyPOI ?? "周边景点")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("距离您: 30米")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("了解") {
                        withAnimation {
                            showInfoPopup = false
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.blue))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 10)
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
        .onAppear {
            setupRouteSimulation()
            initializeRouteInfo()
        }
        .onDisappear {
            simulationPlayer.stopPlaying()
        }
    }
    
    // 初始化路线信息
    private func initializeRouteInfo() {
        // 设置总距离和总时间（从路线信息中获取）
        totalDistance = route.distance
        totalTime = route.duration
    }
    
    // 设置路线模拟
    private func setupRouteSimulation() {
        guard let routeMK = route.route else { return }
        
        // 设置播放器
        simulationPlayer.loadRoute(routeMK)
        
        // 设置位置监听
        simulationPlayer.onPositionChanged = { location, index in
            // 更新模拟小人位置
            avatarLocation = location
            avatarHeading = simulationPlayer.currentHeading
            
            // 更新状态信息
            updateStatusInfo()
            
            // 检查附近POI (每隔几个点检查一次)
            if index % 5 == 0 {
                checkNearbyPOI(at: location)
            }
        }
        
        // 初始化位置
        if let startLocation = simulationPlayer.currentLocation {
            avatarLocation = startLocation
            avatarHeading = simulationPlayer.currentHeading
            updateStatusInfo()
        }
    }
    
    // 更新状态信息 - 简化版本，只更新进度百分比
    private func updateStatusInfo() {
        // 计算总路线距离和进度百分比
        if let routeDistance = route.route?.distance {
            // 计算剩余距离
            let remaining = simulationPlayer.getRemainingDistance()
            let completed = routeDistance - remaining
            
            // 更新进度百分比（确保在0-1之间）
            completionPercentage = min(1.0, max(0.0, completed / routeDistance))
        }
    }
    
    // 简化的POI检测
    private func checkNearbyPOI(at location: CLLocationCoordinate2D) {
        // 简化的POI检测逻辑
        nearbyPOI = nil
    }
}

// 3D地图模拟视图
struct SimulationMap3DView: UIViewRepresentable {
    let route: MKRoute?
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let avatarLocation: CLLocationCoordinate2D?
    let avatarHeading: Double
    let followsAvatar: Bool
    let transportType: TransportationType
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsBuildings = true
        mapView.showsTraffic = true
        mapView.pointOfInterestFilter = .includingAll
        
        // 设置3D视图
        let camera = MKMapCamera()
        camera.pitch = 60 // 倾斜角度
        camera.altitude = 300 // 高度（米）
        mapView.camera = camera
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 清除现有覆盖物和标注
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // 添加路线
        if let route = route {
            mapView.addOverlay(route.polyline)
        }
        
        // 添加起点和终点标注
        if let start = startCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            mapView.addAnnotation(startAnnotation)
        }
        
        if let end = endCoordinate {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "终点"
            mapView.addAnnotation(endAnnotation)
        }
        
        // 添加小人标注
        if let location = avatarLocation {
            let avatarAnnotation = AvatarAnnotation(
                coordinate: location,
                heading: avatarHeading,
                transportType: transportType
            )
            mapView.addAnnotation(avatarAnnotation)
            
            // 如果需要跟随小人，更新相机
            if followsAvatar {
                // 创建一个在小人前方的相机位置
                let camera = mapView.camera
                camera.centerCoordinate = location
                
                // 设置相机朝向与小人一致
                camera.heading = avatarHeading
                
                // 调整高度和倾斜
                camera.altitude = 150 // 米
                camera.pitch = 60 // 度
                
                // 平滑过渡到新相机位置
                mapView.setCamera(camera, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: SimulationMap3DView
        
        init(_ parent: SimulationMap3DView) {
            self.parent = parent
        }
        
        // 路线渲染
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 8
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        // 标注视图
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            if let avatarAnnotation = annotation as? AvatarAnnotation {
                let identifier = "AvatarAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: avatarAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false
                } else {
                    annotationView?.annotation = avatarAnnotation
                }
                
                // 根据交通方式使用不同图标
                let image = UIImage(systemName: avatarAnnotation.transportType.simulationIcon)?
                    .withTintColor(avatarAnnotation.transportType.color.toUIColor(), renderingMode: .alwaysOriginal)
                annotationView?.image = image
                
                // 根据朝向旋转图像
                if let heading = (annotation as? AvatarAnnotation)?.heading {
                    annotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(heading * Double.pi / 180.0))
                }
                
                return annotationView
            } else {
                let identifier = "PinAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                if annotation.title == "起点" {
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "location.circle.fill")
                } else if annotation.title == "终点" {
                    annotationView?.markerTintColor = .systemRed
                    annotationView?.glyphImage = UIImage(systemName: "flag.circle.fill")
                }
                
                return annotationView
            }
        }
    }
}

// 2D地图模拟视图
struct SimulationMapView: UIViewRepresentable {
    let route: MKRoute?
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let avatarLocation: CLLocationCoordinate2D?
    let avatarHeading: Double
    let followsAvatar: Bool
    let transportType: TransportationType
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsTraffic = true
        mapView.pointOfInterestFilter = .includingAll
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 与3D视图相同的更新逻辑，但不设置3D相机
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        if let route = route {
            mapView.addOverlay(route.polyline)
        }
        
        if let start = startCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            mapView.addAnnotation(startAnnotation)
        }
        
        if let end = endCoordinate {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "终点"
            mapView.addAnnotation(endAnnotation)
        }
        
        if let location = avatarLocation {
            let avatarAnnotation = AvatarAnnotation(
                coordinate: location,
                heading: avatarHeading,
                transportType: transportType
            )
            mapView.addAnnotation(avatarAnnotation)
            
            if followsAvatar {
                // 2D地图只需要设置区域
                let region = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: SimulationMapView
        
        init(_ parent: SimulationMapView) {
            self.parent = parent
        }
        
        // 与3D视图相同的委托方法
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            if let avatarAnnotation = annotation as? AvatarAnnotation {
                let identifier = "AvatarAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: avatarAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false
                } else {
                    annotationView?.annotation = avatarAnnotation
                }
                
                // 根据交通方式使用不同图标
                let image = UIImage(systemName: avatarAnnotation.transportType.simulationIcon)?
                    .withTintColor(avatarAnnotation.transportType.color.toUIColor(), renderingMode: .alwaysOriginal)
                annotationView?.image = image
                
                if let heading = (annotation as? AvatarAnnotation)?.heading {
                    annotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(heading * Double.pi / 180.0))
                }
                
                return annotationView
            } else {
                let identifier = "PinAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                if annotation.title == "起点" {
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "location.circle.fill")
                } else if annotation.title == "终点" {
                    annotationView?.markerTintColor = .systemRed
                    annotationView?.glyphImage = UIImage(systemName: "flag.circle.fill")
                }
                
                return annotationView
            }
        }
    }
}

// 小人标注类
class AvatarAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var heading: Double
    var transportType: TransportationType
    
    init(coordinate: CLLocationCoordinate2D, heading: Double, transportType: TransportationType) {
        self.coordinate = coordinate
        self.heading = heading
        self.transportType = transportType
        super.init()
    }
}

// 为TransportationType添加模拟图标
extension TransportationType {
    var simulationIcon: String {
        switch self {
        case .walking:
            return "figure.walk.circle.fill"
        case .driving:
            return "car.circle.fill"
        case .publicTransport:
            return "bus.fill"
        }
    }
    
    // 用于转换SwiftUI Color为UIKit UIColor
    func toUIColor() -> UIColor {
        switch self {
        case .walking:
            return UIColor.systemGreen
        case .driving:
            return UIColor.systemBlue
        case .publicTransport:
            return UIColor.systemOrange
        }
    }
}

// UIColor与SwiftUI Color转换
extension Color {
    func toUIColor() -> UIColor {
        UIColor(self)
    }
}
