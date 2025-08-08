//
//  RouteType.swift
//  ScenePath
//
//  路线类型枚举 - 更新版
//

import SwiftUI

enum RouteType: String, CaseIterable {
    case fastest = "最快路线"
    case shortest = "最短路线"
    case cheapest = "最省钱"
    case scenic = "风景路线"
    case recommended = "推荐路线"
    case alternative = "备选路线"
    
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
        case .recommended:
            return "star.fill"
        case .alternative:
            return "arrow.triangle.branch"
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
        case .recommended:
            return .orange
        case .alternative:
            return .gray
        }
    }
}
