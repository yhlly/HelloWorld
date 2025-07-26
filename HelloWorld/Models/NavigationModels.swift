//
//  NavigationModels.swift
//  HelloWorld
//
//  导航相关数据模型 - 更新版
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

// 导航指令数据结构
struct NavigationInstruction {
    let id = UUID()
    let instruction: String
    let distance: String
    let icon: String
    let coordinate: CLLocationCoordinate2D
}

// 路线信息数据结构 - 添加特殊路线支持
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
    let specialRouteType: SpecialRouteType // 新增特殊路线类型
    let highlights: [String] // 新增路线亮点
    let difficulty: RouteDifficulty // 新增路线难度
}

// 路线难度枚举
enum RouteDifficulty: String, CaseIterable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var color: Color {
        switch self {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .easy:
            return "1.circle.fill"
        case .medium:
            return "2.circle.fill"
        case .hard:
            return "3.circle.fill"
        }
    }
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

// 特殊路线搜索配置
struct SpecialRouteConfig {
    let specialType: SpecialRouteType
    let transportType: TransportationType
    let maxDetourPercentage: Double // 最大绕行百分比
    let priorityKeywords: [String] // 优先搜索关键词
    
    init(specialType: SpecialRouteType, transportType: TransportationType) {
        self.specialType = specialType
        self.transportType = transportType
        
        // 根据特殊路线类型设置绕行百分比
        switch specialType {
        case .none:
            self.maxDetourPercentage = 0
        case .scenic, .nature:
            self.maxDetourPercentage = 50
        case .food, .attractions, .shopping:
            self.maxDetourPercentage = 30
        case .cultural, .nightlife:
            self.maxDetourPercentage = 25
        }
        
        // 根据特殊路线类型设置搜索关键词
        switch specialType {
        case .none:
            self.priorityKeywords = []
        case .scenic:
            self.priorityKeywords = ["公园", "湖泊", "河流", "山", "景区", "观景台"]
        case .food:
            self.priorityKeywords = ["餐厅", "小吃", "美食", "咖啡", "茶楼", "食堂"]
        case .attractions:
            self.priorityKeywords = ["景点", "博物馆", "纪念馆", "古迹", "广场", "地标"]
        case .shopping:
            self.priorityKeywords = ["商场", "购物中心", "商业街", "市场", "商店"]
        case .cultural:
            self.priorityKeywords = ["博物馆", "美术馆", "图书馆", "剧院", "文化中心"]
        case .nature:
            self.priorityKeywords = ["森林", "植物园", "自然保护区", "湿地", "绿地"]
        case .nightlife:
            self.priorityKeywords = ["酒吧", "KTV", "夜市", "娱乐城", "夜店"]
        }
    }
}
