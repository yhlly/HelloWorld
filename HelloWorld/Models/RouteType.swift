//
//  RouteType.swift
//  HelloWorld
//
//  路线类型枚举
//

import SwiftUI

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
