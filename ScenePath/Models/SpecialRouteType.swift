//
//  SpecialRouteType.swift
//  HelloWorld
//
//  特殊路线类型枚举
//

import SwiftUI

enum SpecialRouteType: String, CaseIterable {
    case none = "常规路线"
    case scenic = "风景路线"
    case food = "美食路线"
    case attractions = "景点路线"
    
    var icon: String {
        switch self {
        case .none:
            return "road.lanes"
        case .scenic:
            return "mountain.2.fill"
        case .food:
            return "fork.knife"
        case .attractions:
            return "camera.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .none:
            return .gray
        case .scenic:
            return .green
        case .food:
            return .orange
        case .attractions:
            return .blue
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "选择最优路线，综合考虑时间和距离"
        case .scenic:
            return "沿途欣赏美丽风景，经过公园、河流等景观区域"
        case .food:
            return "途径热门餐厅和小吃店，体验当地美食文化"
        case .attractions:
            return "经过知名景点和地标建筑，适合观光游览"
        }
    }
    
    var tags: [String] {
        switch self {
        case .none:
            return ["高效", "常规"]
        case .scenic:
            return ["风景", "拍照", "休闲"]
        case .food:
            return ["美食", "餐厅", "小吃"]
        case .attractions:
            return ["景点", "观光", "拍照"]
        }
    }
}
