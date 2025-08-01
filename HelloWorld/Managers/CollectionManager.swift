//
//  CollectionManager.swift
//  HelloWorld
//
//  增强的收集功能管理器 - 带详细Debug
//

import Foundation
import SwiftData
import CoreLocation
import Combine

@Observable
class CollectionManager {
    private var modelContext: ModelContext?
    
    // 当前可收集的点位
    var availableCollectibles: [CollectiblePoint] = []
    
    // 已收集的物品
    var collectedItems: [CollectibleItem] = []
    
    // 当前用户位置
    var currentLocation: CLLocationCoordinate2D?
    
    // 收集范围（米）
    private let collectionRadius: Double = 100
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("🎯 DEBUG: CollectionManager 初始化")
        loadCollectedItems()
    }
    
    // 基于特殊路线类型和导航指令生成可收集点
    func generateCollectiblePoints(for specialRouteType: SpecialRouteType, instructions: [NavigationInstruction]) {
        print("🎯 DEBUG: generateCollectiblePoints 开始")
        print("  🎯 路线类型: \(specialRouteType.rawValue)")
        print("  🎯 指令数量: \(instructions.count)")
        
        guard specialRouteType != .none else {
            print("  ⚠️ 常规路线，不生成收集点")
            availableCollectibles = []
            return
        }
        
        var points: [CollectiblePoint] = []
        
        // 根据特殊路线类型确定收集点类别
        let categories = getCategoriesForRouteType(specialRouteType)
        print("  🎯 可用类别: \(categories.map { $0.rawValue })")
        
        // 为路线上的关键点生成收集点
        for (index, instruction) in instructions.enumerated() {
            // 每隔2-3个导航点生成一个收集点，确保有足够的收集点
            if index % 2 == 1 || index % 3 == 2 {
                let category = categories.randomElement() ?? .food
                let point = generateCollectiblePoint(
                    near: instruction.coordinate,
                    category: category,
                    routeType: specialRouteType
                )
                points.append(point)
                print("  📍 生成收集点 \(points.count): \(point.name) (\(point.category.rawValue))")
            }
        }
        
        // 添加一些随机的额外收集点，确保有足够的密度
        let extraCount = max(2, instructions.count / 3)
        let extraPoints = generateRandomCollectiblePoints(
            along: instructions,
            categories: categories,
            count: extraCount
        )
        points.append(contentsOf: extraPoints)
        
        print("  📍 额外生成 \(extraPoints.count) 个收集点")
        
        availableCollectibles = points
        print("🎯 DEBUG: 总共生成了 \(points.count) 个收集点")
        
        // 打印所有收集点详情
        for (index, point) in points.enumerated() {
            print("  \(index + 1). \(point.name) - \(point.category.rawValue) - 坐标: (\(String(format: "%.4f", point.coordinate.latitude)), \(String(format: "%.4f", point.coordinate.longitude)))")
        }
        
        // 检查哪些已经被收集过了
        updateCollectionStatus()
    }
    
    // 更新用户位置并检查可收集的点
    func updateLocation(_ location: CLLocationCoordinate2D) {
        currentLocation = location
        print("🎯 DEBUG: updateLocation")
        print("  📍 新位置: (\(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude)))")
        
        // 计算范围内的收集点
        let inRange = collectiblesInRange(of: location)
        print("  🎯 范围内收集点: \(inRange.count) 个")
        
        for collectible in inRange {
            let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
                .distance(from: CLLocation(latitude: collectible.coordinate.latitude, longitude: collectible.coordinate.longitude))
            print("    - \(collectible.name): \(Int(distance))米")
        }
    }
    
    // 检查指定坐标是否在收集范围内
    func collectiblesInRange(of location: CLLocationCoordinate2D) -> [CollectiblePoint] {
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        let inRange = availableCollectibles.filter { point in
            if point.isCollected { 
                print("🎯 DEBUG: \(point.name) 已收集，跳过")
                return false 
            }
            
            let pointLocation = CLLocation(latitude: point.coordinate.latitude, 
                                         longitude: point.coordinate.longitude)
            let distance = userLocation.distance(from: pointLocation)
            let isInRange = distance <= collectionRadius
            
            if isInRange {
                print("🎯 DEBUG: \(point.name) 在范围内 (\(Int(distance))米)")
            }
            
            return isInRange
        }
        
        print("🎯 DEBUG: collectiblesInRange 返回 \(inRange.count) 个收集点")
        return inRange
    }
    
    // 收集物品
    func collectItem(_ point: CollectiblePoint, routeType: SpecialRouteType) {
        print("🎯 DEBUG: collectItem 开始")
        print("  🎯 收集点: \(point.name)")
        print("  🎯 类别: \(point.category.rawValue)")
        print("  🎯 路线类型: \(routeType.rawValue)")
        
        guard let context = modelContext else { 
            print("  ❌ ModelContext 为空")
            return 
        }
        
        // 检查是否已经收集过相同位置和类型的物品
        let alreadyCollected = collectedItems.contains { item in
            let distance = CLLocation(latitude: item.latitude, longitude: item.longitude)
                .distance(from: CLLocation(latitude: point.coordinate.latitude, 
                                         longitude: point.coordinate.longitude))
            let isSameTypeAndLocation = distance < 50 && item.category == point.category
            
            if isSameTypeAndLocation {
                print("  🎯 DEBUG: 发现重复收集 - \(item.name) 距离: \(Int(distance))米")
            }
            
            return isSameTypeAndLocation
        }
        
        if alreadyCollected {
            print("  ⚠️ 物品已收集过，跳过")
            return
        }
        
        // 创建新的收集物品
        let newItem = CollectibleItem(
            name: point.name,
            category: point.category,
            coordinate: point.coordinate,
            routeType: routeType,
            description: point.description
        )
        
        print("  🎯 创建新收集物品: \(newItem.name)")
        
        // 保存到SwiftData
        context.insert(newItem)
        
        do {
            try context.save()
            collectedItems.append(newItem)
            
            print("  ✅ 收集成功！")
            print("    - 物品ID: \(newItem.id)")
            print("    - 收集时间: \(newItem.collectedAt)")
            print("    - 总收集数: \(collectedItems.count)")
            
            // 更新可收集点状态
            updateCollectionStatus()
            
        } catch {
            print("  ❌ 收集失败: \(error.localizedDescription)")
            print("    - 错误详情: \(error)")
        }
    }
    
    // 加载已收集的物品
    private func loadCollectedItems() {
        print("🎯 DEBUG: loadCollectedItems 开始")
        
        guard let context = modelContext else { 
            print("  ❌ ModelContext 为空")
            return 
        }
        
        do {
            let descriptor = FetchDescriptor<CollectibleItem>(
                sortBy: [SortDescriptor(\.collectedAt, order: .reverse)]
            )
            collectedItems = try context.fetch(descriptor)
            print("  ✅ 成功加载 \(collectedItems.count) 个已收集物品")
            
            // 打印已收集物品详情
            for (index, item) in collectedItems.enumerated() {
                print("    \(index + 1). \(item.name) (\(item.category.rawValue)) - \(item.collectedAt)")
            }
            
        } catch {
            print("  ❌ 加载收集物品失败: \(error.localizedDescription)")
            collectedItems = []
        }
    }
    
    // 更新收集状态
    private func updateCollectionStatus() {
        print("🎯 DEBUG: updateCollectionStatus 开始")
        
        var updatedCollectibles: [CollectiblePoint] = []
        
        for point in availableCollectibles {
            let isCollected = collectedItems.contains { item in
                let distance = CLLocation(latitude: item.latitude, longitude: item.longitude)
                    .distance(from: CLLocation(latitude: point.coordinate.latitude, 
                                             longitude: point.coordinate.longitude))
                return distance < 50 && item.category == point.category
            }
            
            let updatedPoint = CollectiblePoint(
                name: point.name,
                category: point.category,
                coordinate: point.coordinate,
                description: point.description,
                isCollected: isCollected
            )
            
            updatedCollectibles.append(updatedPoint)
            
            if isCollected && !point.isCollected {
                print("  🎯 标记为已收集: \(point.name)")
            }
        }
        
        availableCollectibles = updatedCollectibles
        
        let collectedCount = availableCollectibles.filter { $0.isCollected }.count
        print("  📊 状态更新完成: \(collectedCount)/\(availableCollectibles.count) 已收集")
    }
    
    // 根据路线类型获取收集点类别
    private func getCategoriesForRouteType(_ routeType: SpecialRouteType) -> [CollectibleCategory] {
        let categories: [CollectibleCategory]
        
        switch routeType {
        case .food:
            categories = [.food, .culture] // 美食路线：美食 + 文化
        case .scenic:
            categories = [.scenic, .landmark] // 风景路线：风景 + 地标
        case .attractions:
            categories = [.attraction, .culture, .landmark] // 景点路线：景点 + 文化 + 地标
        case .none:
            categories = []
        }
        
        print("🎯 DEBUG: 路线类型 \(routeType.rawValue) 对应类别: \(categories.map { $0.rawValue })")
        return categories
    }
    
    // 生成单个收集点
    private func generateCollectiblePoint(near coordinate: CLLocationCoordinate2D, category: CollectibleCategory, routeType: SpecialRouteType) -> CollectiblePoint {
        // 在指定坐标附近随机生成一个点（50-200米范围内）
        let distance = Double.random(in: 50...200)
        let angle = Double.random(in: 0...(2 * .pi))
        
        let deltaLat = distance * cos(angle) / 111000 // 大约111000米每度纬度
        let deltaLng = distance * sin(angle) / (111000 * cos(coordinate.latitude * .pi / 180))
        
        let newCoordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude + deltaLat,
            longitude: coordinate.longitude + deltaLng
        )
        
        let name = generateNameForCategory(category)
        
        print("🎯 DEBUG: 生成收集点")
        print("  📍 基础坐标: (\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude)))")
        print("  📍 偏移: 距离\(Int(distance))米, 角度\(String(format: "%.1f", angle * 180 / .pi))度")
        print("  📍 最终坐标: (\(String(format: "%.4f", newCoordinate.latitude)), \(String(format: "%.4f", newCoordinate.longitude)))")
        print("  🎯 名称: \(name)")
        
        return CollectiblePoint(
            name: name,
            category: category,
            coordinate: newCoordinate
        )
    }
    
    // 生成随机收集点
    private func generateRandomCollectiblePoints(along instructions: [NavigationInstruction], categories: [CollectibleCategory], count: Int) -> [CollectiblePoint] {
        print("🎯 DEBUG: generateRandomCollectiblePoints")
        print("  🎯 需要生成: \(count) 个")
        print("  🎯 指令数量: \(instructions.count)")
        print("  🎯 类别: \(categories.map { $0.rawValue })")
        
        var points: [CollectiblePoint] = []
        
        for i in 0..<count {
            guard let randomInstruction = instructions.randomElement(),
                  let category = categories.randomElement() else { 
                print("    ❌ 第\(i+1)个点生成失败：无可用指令或类别")
                continue 
            }
            
            let point = generateCollectiblePoint(
                near: randomInstruction.coordinate,
                category: category,
                routeType: .food // 这里传入什么都可以，因为只是用来生成点位
            )
            points.append(point)
            print("    ✅ 第\(i+1)个点: \(point.name)")
        }
        
        print("  📊 实际生成: \(points.count) 个随机收集点")
        return points
    }
    
    // 为类别生成名称
    private func generateNameForCategory(_ category: CollectibleCategory) -> String {
        let names: [String]
        
        switch category {
        case .food:
            names = ["特色小吃店", "传统茶楼", "网红咖啡厅", "老字号餐厅", "街边美食", "特色面馆", "手工糕点店", "地方特色菜", "小笼包店", "烧饼铺"]
        case .scenic:
            names = ["观景台", "樱花小径", "湖心亭", "古桥风光", "山顶美景", "河岸风光", "花园小径", "竹林幽径", "石桥美景", "湖边栈道"]
        case .attraction:
            names = ["历史古迹", "文化展馆", "艺术画廊", "纪念碑", "传统建筑", "文化街区", "古建筑群", "历史博物馆", "文物保护区", "古典园林"]
        case .landmark:
            names = ["地标建筑", "城市雕塑", "历史纪念碑", "标志性建筑", "著名广场", "特色建筑", "城市地标", "标志性塔楼", "纪念性建筑", "城市象征"]
        case .culture:
            names = ["文化中心", "传统工艺", "民俗体验", "艺术展示", "文化遗产", "传统表演", "手工艺坊", "文化体验馆", "民俗博物馆", "艺术工作室"]
        }
        
        let selectedName = names.randomElement() ?? category.rawValue
        print("🎯 DEBUG: 为类别 \(category.rawValue) 生成名称: \(selectedName)")
        return selectedName
    }
    
    // 获取收集统计
    func getCollectionStats() -> (total: Int, byCategory: [CollectibleCategory: Int]) {
        var byCategory: [CollectibleCategory: Int] = [:]
        
        for item in collectedItems {
            byCategory[item.category, default: 0] += 1
        }
        
        let stats = (total: collectedItems.count, byCategory: byCategory)
        print("🎯 DEBUG: getCollectionStats")
        print("  📊 总数: \(stats.total)")
        for (category, count) in byCategory {
            print("  📊 \(category.rawValue): \(count)")
        }
        
        return stats
    }
    
    // 清除所有收集点（用于调试）
    func clearAllCollectibles() {
        print("🎯 DEBUG: clearAllCollectibles")
        availableCollectibles.removeAll()
        print("  ✅ 已清除所有收集点")
    }
    
    // 强制刷新收集状态（用于调试）
    func refreshCollectionStatus() {
        print("🎯 DEBUG: refreshCollectionStatus")
        loadCollectedItems()
        updateCollectionStatus()
        print("  ✅ 刷新完成")
    }
}
