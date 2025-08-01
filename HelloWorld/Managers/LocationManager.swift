//
//  LocationManager.swift
//  HelloWorld
//
//  位置管理器 - 增强版：支持持续位置更新
//

import Foundation
import CoreLocation
import Combine
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentLocationName: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isReverseGeocoding = false
    @Published var locationError: String?
    @Published var heading: CLHeading?
    
    // 新增：导航相关状态
    @Published var isNavigationActive = false
    @Published var speed: Double = 0 // 米/秒
    @Published var course: Double = 0 // 方向，以度为单位
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 设置位置更新距离过滤器
        self.manager.distanceFilter = 5 // 每移动5米更新一次位置
        
        // 立即更新授权状态
        authorizationStatus = manager.authorizationStatus
        print("LocationManager initialized with status: \(authorizationStatus.rawValue)")
    }
    
    func requestLocation() {
        print("LocationManager requestLocation called")
        locationError = nil
        
        let status = manager.authorizationStatus
        print("Current authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("Requesting location permission...")
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("Permission granted, requesting location...")
            isReverseGeocoding = true
            manager.requestLocation()
        case .denied:
            locationError = "位置权限被拒绝，请在设置中开启"
            print("Location permission denied")
        case .restricted:
            locationError = "位置服务受限"
            print("Location services restricted")
        @unknown default:
            locationError = "未知的位置权限状态"
            print("Unknown location permission status")
        }
    }
    
    // 新增：开始导航模式（持续更新位置）
    func startNavigation() {
        isNavigationActive = true
        
        // 更频繁地更新位置和角度
        manager.distanceFilter = 3 // 每移动3米更新一次
        manager.headingFilter = 5 // 每变化5度更新一次方向
        
        // 开始更新位置和方向
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        
        print("🧭 导航模式已开启：持续位置和方向更新")
    }
    
    // 新增：停止导航模式
    func stopNavigation() {
        isNavigationActive = false
        
        // 恢复正常更新频率
        manager.distanceFilter = 5
        
        // 停止持续更新
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        
        print("🧭 导航模式已停止")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorization: \(status.rawValue)")
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("Permission granted in delegate, requesting location...")
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            DispatchQueue.main.async {
                self.isReverseGeocoding = false
                self.locationError = status == .denied ? "位置权限被拒绝" : "位置服务受限"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations called, locations count: \(locations.count)")
        guard let location = locations.last else {
            DispatchQueue.main.async {
                self.isReverseGeocoding = false
            }
            return
        }
        
        print("Got location: \(location.coordinate)")
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            
            // 导航模式下更新速度和方向
            if self.isNavigationActive {
                self.speed = location.speed > 0 ? location.speed : 0
                self.course = location.course >= 0 ? location.course : 0
                print("🧭 导航更新: 速度 \(self.speed)m/s, 方向 \(self.course)°")
            }
        }
        
        // 只在第一次获取位置或者非导航模式下做反向地理编码
        if !isNavigationActive || self.currentLocationName == nil {
            reverseGeocode(location: location)
        } else {
            DispatchQueue.main.async {
                self.isReverseGeocoding = false
            }
        }
    }
    
    // 新增：处理方向更新
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 { return }
        
        DispatchQueue.main.async {
            self.heading = newHeading
            print("🧭 方向更新: \(newHeading.trueHeading)°")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error)")
        DispatchQueue.main.async {
            self.isReverseGeocoding = false
            self.locationError = "获取位置失败: \(error.localizedDescription)"
        }
    }
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isReverseGeocoding = false
                
                if let error = error {
                    print("Reverse geocoding failed: \(error.localizedDescription)")
                    self?.currentLocationName = "当前位置"
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let name = placemark.name, !name.isEmpty {
                        addressComponents.append(name)
                    }
                    
                    if let thoroughfare = placemark.thoroughfare {
                        if let subThoroughfare = placemark.subThoroughfare {
                            addressComponents.append("\(thoroughfare)\(subThoroughfare)")
                        } else {
                            addressComponents.append(thoroughfare)
                        }
                    }
                    
                    if addressComponents.isEmpty {
                        if let subLocality = placemark.subLocality {
                            addressComponents.append(subLocality)
                        }
                        if let locality = placemark.locality {
                            addressComponents.append(locality)
                        }
                    }
                    
                    if !addressComponents.isEmpty {
                        self?.currentLocationName = addressComponents.joined(separator: ", ")
                    } else {
                        self?.currentLocationName = "当前位置"
                    }
                } else {
                    self?.currentLocationName = "当前位置"
                }
                
                print("Address resolved to: \(self?.currentLocationName ?? "nil")")
            }
        }
    }
    
    // 检查是否可以使用位置服务
    var canUseLocation: Bool {
        return authorizationStatus == .authorizedWhenInUse ||
               authorizationStatus == .authorizedAlways ||
               authorizationStatus == .notDetermined
    }
    
    // 新增：获取到某个坐标的距离（米）
    func distanceTo(coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        
        let from = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return from.distance(from: to)
    }
    
    // 新增：检查用户是否接近某个坐标点（用于导航中判断是否到达某个转弯点）
    func isNearCoordinate(_ coordinate: CLLocationCoordinate2D, threshold: Double = 20) -> Bool {
        guard let distance = distanceTo(coordinate: coordinate) else { return false }
        return distance <= threshold
    }
    
    // 新增：计算用户当前位置到路线上最近点的投影（用于判断用户是否偏离路线）
    func findClosestPointOnRoute(route: MKRoute) -> (coordinate: CLLocationCoordinate2D, distance: Double)? {
        guard let userLocation = currentLocation else { return nil }
        
        var closestPoint: CLLocationCoordinate2D?
        var minDistance = Double.greatestFiniteMagnitude
        
        // 遍历路线上的点，找到最近的点
        let pointCount = route.polyline.pointCount
        let points = route.polyline.points()
        
        for i in 0..<pointCount {
            let coordinate = points[i].coordinate
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let distance = userLoc.distance(from: location)
            
            if distance < minDistance {
                minDistance = distance
                closestPoint = coordinate
            }
        }
        
        if let closest = closestPoint {
            return (closest, minDistance)
        }
        
        return nil
    }
}
