//
//  TransportationType.swift
//  HelloWorld
//
//  交通方式枚举
//

import SwiftUI
import MapKit

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
