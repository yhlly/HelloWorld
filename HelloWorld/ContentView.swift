//
//  ContentView.swift
//  HelloWorld
//
//  Enhanced with Precise Location Selection and 3D Map and AR Navigation
//

import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()
    override init() {
        super.init()
        self.manager.delegate = self
    }
    func requestLocation() {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            // Authorization denied or restricted - handle appropriately if needed
            break
        @unknown default:
            break
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorization: \(status.rawValue)")
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations called, locations count: \(locations.count)")
        currentLocation = locations.last?.coordinate
        print("currentLocation set to: \(String(describing: currentLocation))")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error)")
    }
}

// 页面状态枚举
enum AppState {
    case search
    case routePreview
    case map3D
    case arNavigation
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

// 导航指令数据结构
struct NavigationInstruction {
    let id = UUID()
    let instruction: String
    let distance: String
    let icon: String
    let coordinate: CLLocationCoordinate2D
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
    let instructions: [NavigationInstruction]
}

// 位置建议数据结构
struct LocationSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D?
    let completion: MKLocalSearchCompletion?
    
    var displayText: String {
        if subtitle.isEmpty {
            return title
        } else {
            return "\(title), \(subtitle)"
        }
    }
    
    static func == (lhs: LocationSuggestion, rhs: LocationSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

// 搜索管理器
class LocationSearchManager: NSObject, ObservableObject {
    @Published var suggestions: [LocationSuggestion] = []
    @Published var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestions.removeAll()
            return
        }
        
        isSearching = true
        searchCompleter.queryFragment = query
    }
    
    func clearSuggestions() {
        suggestions.removeAll()
        isSearching = false
    }
    
    func getCoordinate(for suggestion: LocationSuggestion, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard let searchCompletion = suggestion.completion else {
            completion(suggestion.coordinate)
            return
        }
        
        let searchRequest = MKLocalSearch.Request(completion: searchCompletion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            DispatchQueue.main.async {
                completion(response?.mapItems.first?.placemark.coordinate)
            }
        }
    }
}

extension LocationSearchManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results.map { completion in
                LocationSuggestion(
                    title: completion.title,
                    subtitle: completion.subtitle,
                    coordinate: nil,
                    completion: completion
                )
            }
            self.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            print("Search completer error: \(error.localizedDescription)")
        }
    }
}

// 增强的地点搜索框组件
struct EnhancedLocationSearchBar: View {
    let placeholder: String
    @Binding var text: String
    @Binding var selectedLocation: LocationSuggestion?
    let icon: String
    @StateObject private var searchManager = LocationSearchManager()
    @State private var showSuggestions = false
    @State private var searchTimer: Timer?
    @State private var justSelected = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 搜索输入框
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: text) { newValue in
                        if justSelected {
                            justSelected = false
                            return
                        }
                        selectedLocation = nil
                        
                        // 防抖搜索
                        searchTimer?.invalidate()
                        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            if !newValue.isEmpty {
                                searchManager.search(query: newValue)
                                showSuggestions = true
                            } else {
                                searchManager.clearSuggestions()
                                showSuggestions = false
                            }
                        }
                    }
                    .onTapGesture {
                        if !text.isEmpty && !searchManager.suggestions.isEmpty {
                            showSuggestions = true
                        }
                    }
                
                // 清除按钮
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        selectedLocation = nil
                        searchManager.clearSuggestions()
                        showSuggestions = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                // 搜索状态指示器
                if searchManager.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 搜索建议下拉列表
            if showSuggestions && !searchManager.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchManager.suggestions.prefix(5)) { suggestion in
                        Button(action: {
                            selectSuggestion(suggestion)
                        }) {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(Color(.systemBackground))
                        
                        if suggestion.id != searchManager.suggestions.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 4)
                .zIndex(1)
            }
        }
        .onTapGesture {
            // 点击外部区域隐藏建议
        }
    }
    
    private func selectSuggestion(_ suggestion: LocationSuggestion) {
        text = suggestion.displayText
        selectedLocation = suggestion
        showSuggestions = false
        searchManager.clearSuggestions()
        justSelected = true
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
                    .background(Color.blue)
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
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 移除之前的路线和标注
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        // 添加起点标注
        if let start = startCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            uiView.addAnnotation(startAnnotation)
        }
        
        // 添加终点标注
        if let end = endCoordinate {
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
        } else if let start = startCoordinate, let end = endCoordinate {
            // 没有路线时，调整地图显示起终点
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (start.latitude + end.latitude) / 2,
                    longitude: (start.longitude + end.longitude) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: abs(start.latitude - end.latitude) * 1.5 + 0.01,
                    longitudeDelta: abs(start.longitude - end.longitude) * 1.5 + 0.01
                )
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
struct Map3DView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: MKRoute?
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @Binding var currentLocationIndex: Int
    let instructions: [NavigationInstruction]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        // 启用3D模式
        mapView.mapType = .standard
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        // 设置3D视角
        let camera = MKMapCamera()
        camera.centerCoordinate = region.center
        camera.altitude = 1000
        camera.pitch = 45
        mapView.setCamera(camera, animated: true)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 移除之前的路线和标注
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        // 添加起点标注
        if let start = startCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            uiView.addAnnotation(startAnnotation)
        }
        
        // 添加终点标注
        if let end = endCoordinate {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "终点"
            uiView.addAnnotation(endAnnotation)
        }
        
        // 添加路线
        if let route = route {
            uiView.addOverlay(route.polyline)
        }
        
        // 添加导航指令标注
        for (index, instruction) in instructions.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = instruction.coordinate
            annotation.title = "步骤 \(index + 1)"
            annotation.subtitle = instruction.instruction
            uiView.addAnnotation(annotation)
        }
        
        // 更新相机位置到当前导航点
        if currentLocationIndex < instructions.count {
            let currentInstruction = instructions[currentLocationIndex]
            let camera = MKMapCamera()
            camera.centerCoordinate = currentInstruction.coordinate
            camera.altitude = 500
            camera.pitch = 60
            uiView.setCamera(camera, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: Map3DView
        
        init(_ parent: Map3DView) {
            self.parent = parent
        }
        
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
            
            let identifier = "NavigationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .systemBlue
                markerView.glyphText = "🧭"
            }
            
            return annotationView
        }
    }
}

// AR导航地图视图
struct ARNavigationMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: MKRoute?
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @Binding var currentLocationIndex: Int
    let instructions: [NavigationInstruction]
    @Binding var userLocation: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        // 设置导航地图样式
        mapView.mapType = .standard
        mapView.showsBuildings = true
        mapView.showsTraffic = true
        mapView.showsPointsOfInterest = true
        
        // 设置导航视角
        let camera = MKMapCamera()
        camera.centerCoordinate = region.center
        camera.altitude = 300
        camera.pitch = 70
        mapView.setCamera(camera, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 移除之前的路线和标注
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        // 添加起点标注
        if let start = startCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            uiView.addAnnotation(startAnnotation)
        }
        
        // 添加终点标注
        if let end = endCoordinate {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "终点"
            uiView.addAnnotation(endAnnotation)
        }
        
        // 添加路线
        if let route = route {
            uiView.addOverlay(route.polyline)
        }
        
        // 添加当前导航点标注
        if currentLocationIndex < instructions.count {
            let currentInstruction = instructions[currentLocationIndex]
            let annotation = MKPointAnnotation()
            annotation.coordinate = currentInstruction.coordinate
            annotation.title = "当前位置"
            annotation.subtitle = currentInstruction.instruction
            uiView.addAnnotation(annotation)
            
            // 更新相机位置到当前导航点
            let camera = MKMapCamera()
            camera.centerCoordinate = currentInstruction.coordinate
            camera.altitude = 200
            camera.pitch = 70
            uiView.setCamera(camera, animated: true)
        }
        
        // 模拟用户位置更新
        if let userLoc = userLocation {
            // 用户位置会通过showsUserLocation自动显示
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ARNavigationMapView
        
        init(_ parent: ARNavigationMapView) {
            self.parent = parent
        }
        
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
            
            let identifier = "NavigationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                if annotation.title == "当前位置" {
                    markerView.markerTintColor = .systemRed
                    markerView.glyphText = "📍"
                } else if annotation.title == "起点" {
                    markerView.markerTintColor = .systemGreen
                    markerView.glyphText = "🚀"
                } else if annotation.title == "终点" {
                    markerView.markerTintColor = .systemBlue
                    markerView.glyphText = "🏁"
                }
            }
            
            return annotationView
        }
    }
}

// AR导航视图
struct ARNavigationView: View {
    let route: RouteInfo
    @Binding var currentLocationIndex: Int
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @State private var isNavigating = false
    @State private var currentSpeed = "0"
    @State private var remainingTime = ""
    @State private var remainingDistance = ""
    @State private var timer: Timer?
    @State private var userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        ZStack {
            // 地图背景
            ARNavigationMapView(
                region: $region,
                route: route.route,
                startCoordinate: $startCoordinate,
                endCoordinate: $endCoordinate,
                currentLocationIndex: $currentLocationIndex,
                instructions: route.instructions,
                userLocation: $userLocation
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // AR叠加层
            VStack(spacing: 0) {
                // 顶部状态栏
                HStack {
                    VStack(alignment: .leading) {
                        Text("剩余时间")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text(remainingTime)
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("剩余距离")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text(remainingDistance)
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("当前速度")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("\(currentSpeed) km/h")
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                )
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // 中央导航指令
                if currentLocationIndex < route.instructions.count {
                    let currentInstruction = route.instructions[currentLocationIndex]
                    
                    VStack(spacing: 15) {
                        // 大型方向指示器
                        Image(systemName: currentInstruction.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 10)
                        
                        // 导航指令文本
                        Text(currentInstruction.instruction)
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // 距离信息
                        Text("在 \(currentInstruction.distance) 处")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 底部控制栏
                HStack(spacing: 20) {
                    Button(action: {
                        // 上一个指令
                        if currentLocationIndex > 0 {
                            currentLocationIndex -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue.opacity(0.8)))
                    }
                    
                    Button(action: {
                        toggleNavigation()
                    }) {
                        Image(systemName: isNavigating ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(isNavigating ? Color.orange.opacity(0.8) : Color.green.opacity(0.8)))
                    }
                    
                    Button(action: {
                        // 下一个指令
                        if currentLocationIndex < route.instructions.count - 1 {
                            currentLocationIndex += 1
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue.opacity(0.8)))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            
            // 进度指示器
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // 导航进度条
                    VStack(alignment: .trailing) {
                        Text("步骤 \(currentLocationIndex + 1)/\(route.instructions.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        ProgressView(value: Float(currentLocationIndex + 1), total: Float(route.instructions.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(width: 100)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(.trailing)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            updateNavigationInfo()
            startNavigationTimer()
        }
        .onDisappear {
            stopNavigationTimer()
        }
    }
    
    private func toggleNavigation() {
        isNavigating.toggle()
        if isNavigating {
            startNavigationTimer()
        } else {
            stopNavigationTimer()
        }
    }
    
    private func startNavigationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // 模拟导航进程
            currentSpeed = String(Int.random(in: 25...65))
            updateNavigationInfo()
            
            // 自动推进导航（模拟）
            if isNavigating && Int.random(in: 1...3) == 1 {
                if currentLocationIndex < route.instructions.count - 1 {
                    currentLocationIndex += 1
                }
            }
        }
    }
    
    private func stopNavigationTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateNavigationInfo() {
        // 模拟计算剩余时间和距离
        let remaining = route.instructions.count - currentLocationIndex
        remainingTime = "\(remaining * 2)分钟"
        remainingDistance = String(format: "%.1f公里", Double(remaining) * 0.3)
    }
}

// 主视图
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var myLocationActive = false
    
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
    
    // 隐藏键盘的手势
    @State private var hideKeyboard = false
    
    var body: some View {
        NavigationView {
            switch currentState {
            case .search:
                searchAndRouteView
            case .routePreview:
                routePreviewView
            case .map3D:
                map3DView
            case .arNavigation:
                arNavigationView
            }
        }
        .onTapGesture {
            // 点击任何地方隐藏键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: locationManager.currentLocation) { oldValue, newValue in
            guard myLocationActive, let coord = newValue else { return }
            // 构造“我的位置” LocationSuggestion
            let myLoc = LocationSuggestion(
                title: "我的位置", subtitle: "Current Location", coordinate: coord, completion: nil
            )
            startLocation = myLoc.displayText
            selectedStartLocation = myLoc
            myLocationActive = false
            checkAutoSearch()
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
                    EnhancedLocationSearchBar(
                        placeholder: "起点",
                        text: $startLocation,
                        selectedLocation: $selectedStartLocation,
                        icon: "location.circle"
                    )
                    .onChange(of: selectedStartLocation) { _ in
                        checkAutoSearch()
                    }
                    
                    HStack {
                        Button(action: {
                            print("使用我的位置 button pressed")
                            myLocationActive = true
                            locationManager.requestLocation()
                        }) {
                            Image(systemName: "location.fill")
                            Text("使用我的位置").font(.callout)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    
                    // 交换按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            // 交换起点和终点
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
                                .font(.title2)
                        }
                        Spacer()
                    }
                    
                    EnhancedLocationSearchBar(
                        placeholder: "终点",
                        text: $endLocation,
                        selectedLocation: $selectedEndLocation,
                        icon: "location.fill"
                    )
                    .onChange(of: selectedEndLocation) { _ in
                        checkAutoSearch()
                    }
                }
                .padding(.horizontal)
                
                // 搜索按钮
                if canSearch && !hasSearched {
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
                
                // 选择的位置显示
                if selectedStartLocation != nil || selectedEndLocation != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let start = selectedStartLocation {
                            HStack {
                                Image(systemName: "location.circle")
                                    .foregroundColor(.green)
                                Text("起点: \(start.displayText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        if let end = selectedEndLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.red)
                                Text("终点: \(end.displayText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
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
            
            // 路线选择区域
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
                                        currentLocationIndex = 0
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
    }
    
    // 检查是否可以搜索
    private var canSearch: Bool {
        return selectedStartLocation != nil && selectedEndLocation != nil
    }
    
    // 自动搜索检查
    private func checkAutoSearch() {
        // 如果两个位置都已选择且还没有搜索过，自动触发搜索
        if canSearch && !hasSearched && !isSearching {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.canSearch && !self.hasSearched && !self.isSearching {
                    self.searchAllRoutes()
                }
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
                
                // 新的导航按钮
                HStack(spacing: 12) {
                    Button("Preview") {
                        currentState = .map3D
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Play") {
                        currentState = .arNavigation
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 地图
            MapViewRepresentable(
                region: $region,
                route: selectedRoute?.route,
                startCoordinate: $startCoordinate,
                endCoordinate: $endCoordinate
            )
            .allowsHitTesting(false)
        }
    }
    
    // 3D地图视图
    private var map3DView: some View {
        VStack(spacing: 0) {
            // 顶部控制栏
            HStack {
                Button("返回") {
                    currentState = .routePreview
                }
                
                Spacer()
                
                Text("3D 地图导航")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("开始导航") {
                    currentState = .arNavigation
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 3D地图
            if let route = selectedRoute {
                Map3DView(
                    region: $region,
                    route: route.route,
                    startCoordinate: $startCoordinate,
                    endCoordinate: $endCoordinate,
                    currentLocationIndex: $currentLocationIndex,
                    instructions: route.instructions
                )
                .allowsHitTesting(false)
            }
            
            // 底部导航指令
            if let route = selectedRoute, currentLocationIndex < route.instructions.count {
                let instruction = route.instructions[currentLocationIndex]
                
                HStack {
                    Image(systemName: instruction.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(instruction.instruction)
                            .font(.headline)
                        Text("在 \(instruction.distance) 处")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            if currentLocationIndex > 0 {
                                currentLocationIndex -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                        
                        Text("\(currentLocationIndex + 1)/\(route.instructions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            if currentLocationIndex < route.instructions.count - 1 {
                                currentLocationIndex += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
        }
    }
    
    // AR导航视图
    private var arNavigationView: some View {
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
    
    // 搜索所有路线
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
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transportType.mkDirectionsTransportType
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response, !response.routes.isEmpty else {
                // 如果没有找到路线，生成模拟路线
                let simulatedRoutes = self.generateSimulatedRoutes(from: start, to: end, transportType: transportType)
                completion(simulatedRoutes)
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
                default:
                    routeType = .scenic
                    price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.9))" : ""
                    description = "风景路线，沿途景色优美"
                }
                
                // 生成导航指令
                let instructions = self.generateNavigationInstructions(for: route, transportType: transportType)
                
                let routeInfo = RouteInfo(
                    type: routeType,
                    transportType: transportType,
                    distance: distance,
                    duration: duration,
                    price: price,
                    route: route,
                    description: description,
                    instructions: instructions
                )
                
                routeInfos.append(routeInfo)
            }
            
            completion(routeInfos)
        }
    }
    
    // 生成模拟路线
    func generateSimulatedRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType) -> [RouteInfo] {
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        
        let distanceKm = distance / 1000
        let baseTime = max(distanceKm * (transportType == .walking ? 12 : transportType == .driving ? 2 : 4), 10)
        
        let instructions = generateSimulatedInstructions(from: start, to: end, transportType: transportType)
        
        return [
            RouteInfo(
                type: .fastest,
                transportType: transportType,
                distance: String(format: "%.1f公里", distanceKm),
                duration: String(format: "%.0f分钟", baseTime),
                price: transportType == .driving ? "¥\(Int(distanceKm * 0.8))" : (transportType == .publicTransport ? "¥3-8" : ""),
                route: nil,
                description: "推荐路线",
                instructions: instructions
            )
        ]
    }
    
    // 生成导航指令
    func generateNavigationInstructions(for route: MKRoute, transportType: TransportationType) -> [NavigationInstruction] {
        var instructions: [NavigationInstruction] = []
        
        // 简化的导航指令生成
        let steps = route.steps
        for (index, step) in steps.enumerated() {
            let instruction: String
            let icon: String
            
            if index == 0 {
                instruction = "开始导航"
                icon = "location.fill"
            } else if index == steps.count - 1 {
                instruction = "到达目的地"
                icon = "flag.fill"
            } else {
                // 根据step的指令生成
                if step.instructions.contains("左转") || step.instructions.contains("左") {
                    instruction = "向左转"
                    icon = "arrow.turn.up.left"
                } else if step.instructions.contains("右转") || step.instructions.contains("右") {
                    instruction = "向右转"
                    icon = "arrow.turn.up.right"
                } else if step.instructions.contains("直行") || step.instructions.contains("继续") {
                    instruction = "继续直行"
                    icon = "arrow.up"
                } else {
                    instruction = step.instructions.isEmpty ? "继续前进" : step.instructions
                    icon = "arrow.up"
                }
            }
            
            // 获取step的起始坐标
            let coordinate: CLLocationCoordinate2D
            if step.polyline.pointCount > 0 {
                let points = step.polyline.points()
                coordinate = points[0].coordinate
            } else {
                // 如果没有点，使用路线的起点或终点
                coordinate = index == 0 ? route.polyline.coordinate : route.polyline.coordinate
            }
            
            let navigationInstruction = NavigationInstruction(
                instruction: instruction,
                distance: String(format: "%.0fm", step.distance),
                icon: icon,
                coordinate: coordinate
            )
            
            instructions.append(navigationInstruction)
        }
        
        return instructions
    }
    
    // 生成模拟导航指令
    func generateSimulatedInstructions(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType) -> [NavigationInstruction] {
        var instructions: [NavigationInstruction] = []
        
        // 创建更多的模拟导航步骤
        let latDiff = end.latitude - start.latitude
        let lngDiff = end.longitude - start.longitude
        let steps = 8 // 增加步骤数量
        
        for i in 0..<steps {
            let progress = Double(i) / Double(steps - 1)
            let coordinate = CLLocationCoordinate2D(
                latitude: start.latitude + latDiff * progress,
                longitude: start.longitude + lngDiff * progress
            )
            
            let instruction: String
            let icon: String
            let distance: String
            
            switch i {
            case 0:
                instruction = "开始导航"
                icon = "location.fill"
                distance = "0m"
            case 1:
                instruction = "继续直行"
                icon = "arrow.up"
                distance = "200m"
            case 2:
                instruction = "向右转"
                icon = "arrow.turn.up.right"
                distance = "150m"
            case 3:
                instruction = "继续直行"
                icon = "arrow.up"
                distance = "300m"
            case 4:
                instruction = "向左转"
                icon = "arrow.turn.up.left"
                distance = "100m"
            case 5:
                instruction = "继续直行"
                icon = "arrow.up"
                distance = "250m"
            case 6:
                instruction = "向右转"
                icon = "arrow.turn.up.right"
                distance = "80m"
            case 7:
                instruction = "到达目的地"
                icon = "flag.fill"
                distance = "50m"
            default:
                instruction = "继续前进"
                icon = "arrow.up"
                distance = "100m"
            }
            
            instructions.append(NavigationInstruction(
                instruction: instruction,
                distance: distance,
                icon: icon,
                coordinate: coordinate
            ))
        }
        
        return instructions
    }
}

#Preview {
    ContentView()
}

