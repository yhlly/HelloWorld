//
//  RouteSimulationView.swift
//  ScenePath
//
//  路线模拟视图 - 用户可沿路线一步步前进
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
    
    // Keep these states for compatibility with the rest of the code
    @State private var avatarLocation: CLLocationCoordinate2D?
    @State private var avatarHeading: Double = 0
    @State private var remainingDistance: String = "计算中..."
    @State private var remainingTime: String = "计算中..."
    @State private var nearbyPOI: String? = nil
    @State private var showInfoPopup: Bool = false
    // Remove the street name variable that contains Beijing streets
    // @State private var currentStreet: String = "未知道路"
    
    // 显示设置
    @State private var showMap3D: Bool = true
    @State private var cameraFollowsAvatar: Bool = true
    
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
                    followsAvatar: cameraFollowsAvatar
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                SimulationMapView(
                    route: route.route,
                    startCoordinate: startCoordinate,
                    endCoordinate: endCoordinate,
                    avatarLocation: avatarLocation,
                    avatarHeading: avatarHeading,
                    followsAvatar: cameraFollowsAvatar
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
                        Text("路线模拟")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Label(remainingDistance, systemImage: "arrow.triangle.swap")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Label(remainingTime, systemImage: "clock")
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
                
                // Position information removed to prevent displaying incorrect street names
                
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
        }
        .onDisappear {
            simulationPlayer.stopPlaying()
        }
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
    
    // Update status info without street names
    private func updateStatusInfo() {
        // Calculate remaining distance
        let distance = simulationPlayer.getRemainingDistance()
        remainingDistance = distance < 1000 ?
            String(format: "%.0f米", distance) :
            String(format: "%.1f公里", distance / 1000)
        
        // Calculate remaining time
        let time = simulationPlayer.getEstimatedRemainingTime(averageSpeed: 5.0) // Assume average 5m/s
        if time < 60 {
            remainingTime = String(format: "%.0f秒", time)
        } else if time < 3600 {
            remainingTime = String(format: "%.0f分钟", time / 60)
        } else {
            remainingTime = String(format: "%.1f小时", time / 3600)
        }
    }
    
    // Remove the updateStreetName method that contained Beijing street names
    /*
    private func updateStreetName() {
        // 在实际应用中，这里应该使用逆地理编码获取真实街道名
        // 这里简单模拟一些街道名
        let streets = ["中关村大街", "学院路", "海淀大街", "清华东路", "北四环西路", "西三环北路", "朝阳路", "建国路"]
        
        // 基于进度随机更新街道名
        let progress = simulationPlayer.getCompletionPercentage()
        if progress < 0.3 {
            currentStreet = streets[Int.random(in: 0...2)]
        } else if progress < 0.7 {
            currentStreet = streets[Int.random(in: 3...5)]
        } else {
            currentStreet = streets[Int.random(in: 6...7)]
        }
    }
    */
    
    // Check for nearby POIs - modified to not display Beijing street names
    private func checkNearbyPOI(at location: CLLocationCoordinate2D) {
        // For simulated POI detection, we'll just keep this minimal
        // and not display street names or random POIs
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
            let avatarAnnotation = AvatarAnnotation(coordinate: location, heading: avatarHeading)
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
                
                // 使用自定义图像
                let image = UIImage(systemName: "figure.walk.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
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
            let avatarAnnotation = AvatarAnnotation(coordinate: location, heading: avatarHeading)
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
                
                let image = UIImage(systemName: "figure.walk.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
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
    
    init(coordinate: CLLocationCoordinate2D, heading: Double) {
        self.coordinate = coordinate
        self.heading = heading
        super.init()
    }
}
