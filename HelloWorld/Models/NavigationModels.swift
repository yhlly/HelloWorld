//
//  NavigationModels.swift
//  HelloWorld
//
//  导航相关数据模型
//

import Foundation
import CoreLocation
import MapKit

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
