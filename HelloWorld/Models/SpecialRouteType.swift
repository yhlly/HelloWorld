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
    case shopping = "购物路线"
    case cultural = "文化路线"
    case nature = "自然路线"
    case nightlife = "夜生活路线"
    
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
        case .shopping:
            return "bag.fill"
        case .cultural:
            return "building.columns.fill"
        case .nature:
            return "leaf.fill"
        case .nightlife:
            return "moon.stars.fill"
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
        case .shopping:
            return .pink
        case .cultural:
            return .purple
        case .nature:
            return .mint
        case .nightlife:
            return .indigo
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
        case .shopping:
            return "路过购物中心和商业街，方便购物休闲"
        case .cultural:
            return "途径博物馆、艺术馆等文化场所"
        case .nature:
            return "选择自然环境优美的路线，远离喧嚣"
        case .nightlife:
            return "经过酒吧、娱乐场所等夜生活丰富的区域"
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
        case .shopping:
            return ["购物", "商场", "消费"]
        case .cultural:
            return ["文化", "历史", "艺术"]
        case .nature:
            return ["自然", "环保", "清静"]
        case .nightlife:
            return ["夜生活", "娱乐", "酒吧"]
        }
    }
}
