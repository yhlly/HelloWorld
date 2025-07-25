//
//  LocationManager.swift
//  HelloWorld
//
//  位置管理器 - 修复版
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentLocationName: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isReverseGeocoding = false
    @Published var locationError: String?
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        
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
        }
        
        reverseGeocode(location: location)
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
}
