//
//  CollectibleItem.swift
//  HelloWorld
//
//  收集物品的SwiftData模型
//

import Foundation
import SwiftData
import CoreLocation

@Model
class CollectibleItem {
    var id: UUID
    var name: String
    var category: CollectibleCategory
    var latitude: Double
    var longitude: Double
    var collectedAt: Date
    var routeType: String // 在哪种特殊路线中收集的
    var itemDescription: String
    var iconName: String
    
    init(name: String, category: CollectibleCategory, coordinate: CLLocationCoordinate2D, routeType: SpecialRouteType, description: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.collectedAt = Date()
        self.routeType = routeType.rawValue
        self.itemDescription = description.isEmpty ? category.defaultDescription : description
        self.iconName = category.iconName
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum CollectibleCategory: String, CaseIterable, Codable {
    case food = "美食"
    case scenic = "风景"
    case attraction = "景点"
    case landmark = "地标"
    case culture = "文化"
    
    var iconName: String {
        switch self {
        case .food:
            return "fork.knife.circle.fill"
        case .scenic:
            return "mountain.2.circle.fill"
        case .attraction:
            return "camera.circle.fill"
        case .landmark:
            return "building.2.circle.fill"
        case .culture:
            return "book.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .food:
            return "orange"
        case .scenic:
            return "green"
        case .attraction:
            return "blue"
        case .landmark:
            return "purple"
        case .culture:
            return "red"
        }
    }
    
    var defaultDescription: String {
        switch self {
        case .food:
            return "发现了一家特色美食店"
        case .scenic:
            return "欣赏到了美丽的风景"
        case .attraction:
            return "探索了有趣的景点"
        case .landmark:
            return "发现了重要的地标建筑"
        case .culture:
            return "体验了当地文化"
        }
    }
}

// 可收集点位数据结构
struct CollectiblePoint: Identifiable {
    let id = UUID()
    let name: String
    let category: CollectibleCategory
    let coordinate: CLLocationCoordinate2D
    let description: String
    let isCollected: Bool
    
    init(name: String, category: CollectibleCategory, coordinate: CLLocationCoordinate2D, description: String = "", isCollected: Bool = false) {
        self.name = name
        self.category = category
        self.coordinate = coordinate
        self.description = description.isEmpty ? category.defaultDescription : description
        self.isCollected = isCollected
    }
}
