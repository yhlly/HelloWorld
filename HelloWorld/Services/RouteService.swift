//
//  RouteService.swift
//  HelloWorld
//
//  路线计算服务 - 修正角度计算和转向判断逻辑
//

import Foundation
import CoreLocation
import MapKit

class RouteService {
    static let shared = RouteService()
    
    private init() {}
    
    // 原有的路线计算方法
    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, completion: @escaping ([RouteInfo]) -> Void) {
        let defaultConfig = SpecialRouteConfig(specialType: .none, transportType: transportType)
        calculateRouteWithSpecialType(from: start, to: end, transportType: transportType, specialConfig: defaultConfig, completion: completion)
    }
    
    // 支持特殊路线的路线计算方法 - 重新实现
    func calculateRouteWithSpecialType(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, specialConfig: SpecialRouteConfig, completion: @escaping ([RouteInfo]) -> Void) {
        
        print("🚀 开始计算路线:")
        print("  📍 起点: (\(start.latitude), \(start.longitude))")
        print("  📍 终点: (\(end.latitude), \(end.longitude))")
        print("  🚗 交通方式: \(transportType.rawValue)")
        print("  🎯 路线类型: \(specialConfig.specialType.rawValue)")
        
        if specialConfig.specialType == .none {
            print("  ➡️ 执行常规路线计算")
            // 常规路线：直接计算最优路线
            calculateNormalRoutes(from: start, to: end, transportType: transportType, completion: completion)
        } else {
            print("  ➡️ 执行特殊路线计算")
            print("  🔍 搜索关键词: \(specialConfig.priorityKeywords)")
            // 特殊路线：先搜索POI，然后计算多段路线
            calculateSpecialRoutes(from: start, to: end, transportType: transportType, specialConfig: specialConfig, completion: completion)
        }
    }
    
    // 计算常规路线
    private func calculateNormalRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, completion: @escaping ([RouteInfo]) -> Void) {
        print("📊 开始计算常规路线...")
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transportType.mkDirectionsTransportType
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response, !response.routes.isEmpty else {
                print("❌ 常规路线计算失败:")
                if let error = error {
                    print("  错误: \(error.localizedDescription)")
                }
                
                // 🚌 特殊处理：如果是公交路线失败，提供模拟公交路线
                if transportType == .publicTransport {
                    print("  🚌 为公交提供模拟路线（MapKit公交数据不可用）")
                    let simulatedTransitRoutes = self.generateSimulatedTransitRoutes(from: start, to: end)
                    completion(simulatedTransitRoutes)
                } else {
                    print("  ➡️ 返回空数组")
                    let simulatedRoutes = self.generateSimulatedNormalRoutes(from: start, to: end, transportType: transportType)
                    completion(simulatedRoutes)
                }
                return
            }
            
            print("✅ 成功获取常规路线，共\(response.routes.count)条:")
            var routeInfos: [RouteInfo] = []
            
            for (index, route) in response.routes.enumerated() {
                // 使用真实的距离和时间数据
                let distance = String(format: "%.1f公里", route.distance / 1000)
                let duration = String(format: "%.0f分钟", route.expectedTravelTime / 60)
                
                print("  📍 路线\(index + 1):")
                print("    🚗 真实距离: \(route.distance)米 -> \(distance)")
                print("    ⏱️ 真实时间: \(route.expectedTravelTime)秒 -> \(duration)")
                print("    📊 数据来源: MapKit真实数据")
                
                let routeType: RouteType = index == 0 ? .fastest : (index == 1 ? .shortest : .alternative)
                
                // 基于真实距离计算价格
                let price: String
                switch transportType {
                case .driving:
                    let fuelCost = Int(route.distance / 1000 * 0.8) // 每公里0.8元油费
                    price = "¥\(fuelCost)"
                case .publicTransport:
                    price = "¥3-8" // 公交固定价格区间
                case .walking:
                    price = ""
                }
                
                print("    💰 价格: \(price)")
                
                let instructions = self.generateNavigationInstructions(for: route, transportType: transportType)
                print("    🧭 导航指令: \(instructions.count)条")
                
                // 基于真实距离确定难度
                let difficulty: RouteDifficulty = route.distance / 1000 < 5 ? .easy : (route.distance / 1000 < 15 ? .medium : .hard)
                
                let routeInfo = RouteInfo(
                    type: routeType,
                    transportType: transportType,
                    distance: distance,
                    duration: duration,
                    price: price,
                    route: route,
                    description: routeType == .fastest ? "推荐路线，路况较好，用时最短" : "备选路线，可能有轻微拥堵",
                    instructions: instructions,
                    specialRouteType: .none,
                    highlights: ["高效出行", "路况良好"],
                    difficulty: difficulty
                )
                
                routeInfos.append(routeInfo)
            }
            
            print("📊 常规路线计算完成，返回\(routeInfos.count)条路线")
            completion(routeInfos)
        }
    }
    
    // 计算特殊路线 - 核心实现
    private func calculateSpecialRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, specialConfig: SpecialRouteConfig, completion: @escaping ([RouteInfo]) -> Void) {
        
        print("🎯 开始计算特殊路线: \(specialConfig.specialType.rawValue)")
        
        // 第一步：搜索相关POI
        searchPOIsForSpecialRoute(from: start, to: end, specialConfig: specialConfig) { pois in
            
            print("🔍 POI搜索结果: 找到\(pois.count)个相关地点")
            for (index, poi) in pois.enumerated() {
                print("  \(index + 1). \(poi.name ?? "未知地点") - \(poi.placemark.title ?? "")")
            }
            
            if pois.isEmpty {
                // 如果没找到POI，fallback到常规路线（使用真实数据）
                print("⚠️ 没有找到适合的\(specialConfig.specialType.rawValue)POI，使用常规路线")
                self.calculateNormalRoutes(from: start, to: end, transportType: transportType, completion: completion)
                return
            }
            
            // 第二步：选择最佳中间点
            let selectedPOIs = self.selectBestPOIs(pois: pois, from: start, to: end, maxCount: 1)
            
            print("🎯 POI选择结果: 从\(pois.count)个中选择了\(selectedPOIs.count)个")
            for (index, poi) in selectedPOIs.enumerated() {
                print("  选中\(index + 1): \(poi.name ?? "未知地点")")
            }
            
            if selectedPOIs.isEmpty {
                // 如果没有合适的中间点，fallback到常规路线（使用真实数据）
                print("⚠️ 没有找到合适的\(specialConfig.specialType.rawValue)中间点，使用常规路线")
                self.calculateNormalRoutes(from: start, to: end, transportType: transportType, completion: completion)
                return
            }
            
            // 第三步：计算多段路线
            print("🛣️ 开始计算多段路线...")
            self.calculateMultiSegmentRoutes(from: start, to: end, waypoints: selectedPOIs, transportType: transportType, specialConfig: specialConfig) { specialRoutes in
                
                print("🛣️ 多段路线计算完成: 得到\(specialRoutes.count)条特殊路线")
                
                if specialRoutes.isEmpty {
                    // 如果特殊路线计算失败，fallback到常规路线
                    print("⚠️ \(specialConfig.specialType.rawValue)路线计算失败，使用常规路线")
                    self.calculateNormalRoutes(from: start, to: end, transportType: transportType, completion: completion)
                    return
                }
                
                // 第四步：同时计算一条常规路线作为对比（如果不是公交）
                if transportType == .publicTransport {
                    // 公交路线通常MapKit数据不可用，直接返回特殊路线
                    print("📊 公交路线完成，直接返回特殊路线（不计算常规对比）")
                    completion(specialRoutes)
                } else {
                    print("📊 计算常规路线作为对比...")
                    self.calculateNormalRoutes(from: start, to: end, transportType: transportType) { normalRoutes in
                        
                        print("📊 路线对比:")
                        print("  🎯 特殊路线: \(specialRoutes.count)条")
                        for (index, route) in specialRoutes.enumerated() {
                            print("    \(index + 1). \(route.type.rawValue) - \(route.distance) - \(route.duration)")
                            print("       描述: \(route.description)")
                            print("       亮点: \(route.highlights.joined(separator: ", "))")
                        }
                        
                        print("  📊 常规路线: \(normalRoutes.count)条")
                        for (index, route) in normalRoutes.enumerated() {
                            print("    \(index + 1). \(route.type.rawValue) - \(route.distance) - \(route.duration)")
                        }
                        
                        // 合并结果，特殊路线在前
                        var allRoutes = specialRoutes
                        if let firstNormalRoute = normalRoutes.first {
                            allRoutes.append(firstNormalRoute)
                        }
                        
                        print("✅ 最终返回\(allRoutes.count)条路线 (特殊路线\(specialRoutes.count)条 + 常规路线\(normalRoutes.count > 0 ? 1 : 0)条)")
                        completion(allRoutes)
                    }
                }
            }
        }
    }
    
    // 搜索POI
    private func searchPOIsForSpecialRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, specialConfig: SpecialRouteConfig, completion: @escaping ([MKMapItem]) -> Void) {
        
        // 计算搜索区域（起终点连线的中点及周围区域）
        let centerLat = (start.latitude + end.latitude) / 2
        let centerLng = (start.longitude + end.longitude) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
        
        // 搜索半径基于起终点距离
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        let searchRadius = min(max(distance / 2, 1000), 10000) // 最小1km，最大10km
        
        print("🔍 POI搜索配置:")
        print("  📍 搜索中心: (\(center.latitude), \(center.longitude))")
        print("  📏 起终点距离: \(Int(distance))米")
        print("  🎯 搜索半径: \(Int(searchRadius))米")
        print("  🔤 搜索关键词: \(specialConfig.priorityKeywords)")
        
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: searchRadius,
            longitudinalMeters: searchRadius
        )
        
        var allPOIs: [MKMapItem] = []
        let searchGroup = DispatchGroup()
        
        // 为每个关键词执行搜索
        for (keywordIndex, keyword) in specialConfig.priorityKeywords.prefix(3).enumerated() { // 限制搜索关键词数量
            searchGroup.enter()
            
            print("  🔍 搜索关键词\(keywordIndex + 1): \(keyword)")
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = keyword
            request.region = region
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                defer { searchGroup.leave() }
                
                if let error = error {
                    print("    ❌ 搜索\(keyword)失败: \(error.localizedDescription)")
                    return
                }
                
                if let response = response {
                    let results = Array(response.mapItems.prefix(5)) // 每个关键词最多5个结果
                    print("    ✅ 搜索\(keyword)成功: 找到\(results.count)个结果")
                    for (index, item) in results.enumerated() {
                        print("      \(index + 1). \(item.name ?? "未知") - \(item.phoneNumber ?? "无电话")")
                    }
                    allPOIs.append(contentsOf: results)
                } else {
                    print("    ⚠️ 搜索\(keyword)无结果")
                }
            }
        }
        
        searchGroup.notify(queue: .main) {
            print("🔍 POI搜索完成: 共找到\(allPOIs.count)个地点")
            completion(allPOIs)
        }
    }
    
    // 选择最佳POI作为中间点
    private func selectBestPOIs(pois: [MKMapItem], from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, maxCount: Int) -> [MKMapItem] {
        
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let directDistance = startLocation.distance(from: endLocation)
        
        // 评分POI
        let scoredPOIs = pois.compactMap { poi -> (poi: MKMapItem, score: Double)? in
            guard let coordinate = poi.placemark.location?.coordinate else { return nil }
            
            let poiLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distanceFromStart = startLocation.distance(from: poiLocation)
            let distanceFromEnd = poiLocation.distance(from: endLocation)
            let totalDistance = distanceFromStart + distanceFromEnd
            
            // 绕行程度：与直线距离的比值
            let detourRatio = totalDistance / directDistance
            
            // 如果绕行太多，跳过
            if detourRatio > 1.8 { return nil }
            
            // 计算分数：距离越近越好，绕行越少越好
            let distanceScore = max(0, 1.0 - (detourRatio - 1.0) / 0.8) // 绕行率越低分数越高
            let positionScore = 1.0 - abs(0.5 - distanceFromStart / totalDistance) * 2 // 位置越居中分数越高
            
            let finalScore = distanceScore * 0.7 + positionScore * 0.3
            
            return (poi: poi, score: finalScore)
        }
        
        // 按分数排序并返回最佳的几个
        let bestPOIs = scoredPOIs
            .sorted { $0.score > $1.score }
            .prefix(maxCount)
            .map { $0.poi }
        
        return Array(bestPOIs)
    }
    
    // 计算多段路线
    private func calculateMultiSegmentRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, waypoints: [MKMapItem], transportType: TransportationType, specialConfig: SpecialRouteConfig, completion: @escaping ([RouteInfo]) -> Void) {
        
        guard let waypoint = waypoints.first,
              let waypointCoordinate = waypoint.placemark.location?.coordinate else {
            print("❌ 无法获取中间点坐标")
            completion([])
            return
        }
        
        print("🛣️ 开始计算多段路线:")
        print("  📍 第一段: 起点 -> \(waypoint.name ?? "中间点")")
        print("  📍 第二段: \(waypoint.name ?? "中间点") -> 终点")
        
        let routeGroup = DispatchGroup()
        var firstSegment: MKRoute?
        var secondSegment: MKRoute?
        var hasError = false
        
        // 计算第一段：起点到中间点
        routeGroup.enter()
        let firstRequest = MKDirections.Request()
        firstRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        firstRequest.destination = waypoint
        firstRequest.transportType = transportType.mkDirectionsTransportType
        
        print("  🔄 计算第一段路线...")
        let firstDirections = MKDirections(request: firstRequest)
        firstDirections.calculate { response, error in
            defer { routeGroup.leave() }
            if let route = response?.routes.first {
                firstSegment = route
                print("  ✅ 第一段路线成功:")
                print("    📏 距离: \(route.distance)米")
                print("    ⏱️ 时间: \(route.expectedTravelTime)秒")
                print("    📊 数据来源: MapKit真实数据")
            } else {
                hasError = true
                print("  ❌ 第一段路线失败:")
                if let error = error {
                    print("    错误: \(error.localizedDescription)")
                }
            }
        }
        
        // 计算第二段：中间点到终点
        routeGroup.enter()
        let secondRequest = MKDirections.Request()
        secondRequest.source = waypoint
        secondRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        secondRequest.transportType = transportType.mkDirectionsTransportType
        
        print("  🔄 计算第二段路线...")
        let secondDirections = MKDirections(request: secondRequest)
        secondDirections.calculate { response, error in
            defer { routeGroup.leave() }
            if let route = response?.routes.first {
                secondSegment = route
                print("  ✅ 第二段路线成功:")
                print("    📏 距离: \(route.distance)米")
                print("    ⏱️ 时间: \(route.expectedTravelTime)秒")
                print("    📊 数据来源: MapKit真实数据")
            } else {
                hasError = true
                print("  ❌ 第二段路线失败:")
                if let error = error {
                    print("    错误: \(error.localizedDescription)")
                }
            }
        }
        
        routeGroup.notify(queue: .main) {
            guard !hasError,
                  let first = firstSegment,
                  let second = secondSegment else {
                // 如果多段路线计算失败，返回空数组，让上层fallback到常规路线
                print("❌ 多段路线计算失败，无法获取真实的\(specialConfig.specialType.rawValue)路线")
                completion([])
                return
            }
            
            print("🔗 开始拼接路线...")
            
            // 拼接路线信息
            let combinedRoute = self.combineRoutes(first: first, second: second, waypoint: waypoint, specialConfig: specialConfig, transportType: transportType)
            
            print("✅ 路线拼接完成:")
            print("  🎯 路线类型: \(combinedRoute.specialRouteType.rawValue)")
            print("  📏 总距离: \(combinedRoute.distance)")
            print("  ⏱️ 总时间: \(combinedRoute.duration)")
            print("  💰 价格: \(combinedRoute.price)")
            print("  📝 描述: \(combinedRoute.description)")
            
            completion([combinedRoute])
        }
    }
    
    // 拼接两段路线 - 使用真实的路线数据
    private func combineRoutes(first: MKRoute, second: MKRoute, waypoint: MKMapItem, specialConfig: SpecialRouteConfig, transportType: TransportationType) -> RouteInfo {
        
        print("🔗 路线拼接详情:")
        print("  📏 第一段距离: \(first.distance)米 (\(String(format: "%.1f公里", first.distance / 1000)))")
        print("  📏 第二段距离: \(second.distance)米 (\(String(format: "%.1f公里", second.distance / 1000)))")
        print("  ⏱️ 第一段时间: \(first.expectedTravelTime)秒 (\(String(format: "%.0f分钟", first.expectedTravelTime / 60)))")
        print("  ⏱️ 第二段时间: \(second.expectedTravelTime)秒 (\(String(format: "%.0f分钟", second.expectedTravelTime / 60)))")
        
        // 使用真实的距离和时间数据
        let totalDistance = first.distance + second.distance
        let totalTime = first.expectedTravelTime + second.expectedTravelTime
        
        let distance = String(format: "%.1f公里", totalDistance / 1000)
        let duration = String(format: "%.0f分钟", totalTime / 60)
        
        print("  📊 拼接结果:")
        print("    📏 总距离: \(totalDistance)米 -> \(distance)")
        print("    ⏱️ 总时间: \(totalTime)秒 -> \(duration)")
        print("    📊 数据来源: MapKit真实数据拼接")
        
        // 基于真实距离计算价格
        let price: String
        switch transportType {
        case .driving:
            let fuelCost = Int(totalDistance / 1000 * 0.8) // 每公里0.8元油费
            price = "¥\(fuelCost)"
            print("    💰 价格计算: \(String(format: "%.1f公里", totalDistance / 1000)) × 0.8元/公里 = \(price)")
        case .publicTransport:
            // 公交价格通常是固定的，稍微增加因为是多段
            price = "¥5-12"
            print("    💰 价格: \(price) (公交多段固定价格)")
        case .walking:
            price = ""
            print("    💰 价格: 免费 (步行)")
        }
        
        // 生成特殊路线的描述和亮点
        let (description, highlights) = self.generateSpecialRouteDescription(specialConfig: specialConfig, waypoint: waypoint)
        print("    📝 路线描述: \(description)")
        print("    ⭐ 路线亮点: \(highlights.joined(separator: ", "))")
        
        // 合并导航指令 - 修复版
        let firstInstructions = generateNavigationInstructions(for: first, transportType: transportType)
        let secondInstructions = generateNavigationInstructions(for: second, transportType: transportType)
        
        print("    🧭 DEBUG: 指令合并前分析:")
        print("      第一段指令数: \(firstInstructions.count)")
        print("      第一段最后一条: \(firstInstructions.last?.instruction ?? "无")")
        print("      第二段指令数: \(secondInstructions.count)")
        print("      第二段前两条: \(secondInstructions.prefix(2).map { $0.instruction })")
        
        var combinedInstructions: [NavigationInstruction] = []
        
        // 1. 添加第一段指令，但排除最后的"到达目的地"
        let firstValidInstructions = firstInstructions.dropLast() // 去掉"到达目的地"
        combinedInstructions.append(contentsOf: firstValidInstructions)
        print("      添加第一段有效指令: \(firstValidInstructions.count)条")
        
        // 2. 在中间点添加特殊指令
        let waypointInstruction = NavigationInstruction(
            instruction: "途径\(waypoint.name ?? "兴趣点")",
            distance: "0m",
            icon: specialConfig.specialType.icon,
            coordinate: waypoint.placemark.coordinate
        )
        combinedInstructions.append(waypointInstruction)
        print("      添加中间点指令: 途径\(waypoint.name ?? "兴趣点")")
        
        // 3. 添加第二段指令，排除"开始导航"但保留所有实际导航指令
        let secondValidInstructions: [NavigationInstruction]
        if secondInstructions.count > 1 &&
           (secondInstructions.first?.instruction.contains("开始导航") ?? false ||
            secondInstructions.first?.instruction.contains("出发") ?? false) {
            // 如果第一条是"开始导航"类型，则跳过
            secondValidInstructions = Array(secondInstructions.dropFirst())
            print("      第二段跳过开始指令，添加: \(secondValidInstructions.count)条")
        } else {
            // 否则保留所有指令
            secondValidInstructions = secondInstructions
            print("      第二段保留所有指令: \(secondValidInstructions.count)条")
        }
        
        combinedInstructions.append(contentsOf: secondValidInstructions)
        
        print("    🧭 导航指令合并完成:")
        print("      第一段有效指令: \(firstValidInstructions.count)条")
        print("      中间点指令: 1条")
        print("      第二段有效指令: \(secondValidInstructions.count)条")
        print("      总计: \(combinedInstructions.count)条")
        
        // Debug: 打印合并后的关键指令
        print("    🧭 合并后指令预览:")
        for (index, instruction) in combinedInstructions.enumerated() {
            if index < 3 || index >= combinedInstructions.count - 3 ||
               instruction.instruction.contains("途径") {
                print("      \(index + 1). \(instruction.instruction)")
            } else if index == 3 {
                print("      ... (省略中间指令)")
            }
        }
        
        // 基于真实距离确定难度
        let difficulty: RouteDifficulty = totalDistance / 1000 < 5 ? .easy : (totalDistance / 1000 < 15 ? .medium : .hard)
        print("    📊 路线难度: \(difficulty.rawValue) (基于总距离\(String(format: "%.1f公里", totalDistance / 1000)))")
        
        return RouteInfo(
            type: .recommended,
            transportType: transportType,
            distance: distance,
            duration: duration,
            price: price,
            route: first, // 主要使用第一段路线用于地图显示
            description: description,
            instructions: combinedInstructions,
            specialRouteType: specialConfig.specialType,
            highlights: highlights,
            difficulty: difficulty
        )
    }
    
    // 生成特殊路线描述
    private func generateSpecialRouteDescription(specialConfig: SpecialRouteConfig, waypoint: MKMapItem) -> (description: String, highlights: [String]) {
        let waypointName = waypoint.name ?? "兴趣点"
        
        switch specialConfig.specialType {
        case .scenic:
            return (
                description: "风景路线，途径\(waypointName)，欣赏沿途美景",
                highlights: [waypointName, "风景优美", "拍照胜地"]
            )
        case .food:
            return (
                description: "美食路线，途径\(waypointName)，体验当地美食",
                highlights: [waypointName, "美食体验", "当地特色"]
            )
        case .attractions:
            return (
                description: "景点路线，途径\(waypointName)，探索文化地标",
                highlights: [waypointName, "文化探索", "历史古迹"]
            )
        case .none:
            return (
                description: "常规路线",
                highlights: ["高效出行"]
            )
        }
    }
    
    // 生成模拟公交路线（当MapKit公交数据不可用时）
    private func generateSimulatedTransitRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [RouteInfo] {
        print("🚌 生成模拟公交路线...")
        
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        
        let distanceKm = distance / 1000
        print("  📏 直线距离: \(String(format: "%.1f公里", distanceKm))")
        
        // 公交路线通常比直线距离长20-40%
        let transitDistanceMultiplier = 1.3
        let transitDistance = distanceKm * transitDistanceMultiplier
        
        // 公交时间计算：等车时间 + 行驶时间 + 换乘时间
        let baseTime = max(transitDistance * 3, 15) // 每公里3分钟 + 最少15分钟
        let waitTime = 8.0 // 平均等车时间
        let transferTime = distanceKm > 3 ? 5.0 : 0.0 // 长距离可能需要换乘
        
        let instructions = generateSimulatedTransitInstructions(from: start, to: end, distance: transitDistance)
        
        print("  🚌 公交路线计算:")
        print("    📏 预估距离: \(String(format: "%.1f公里", transitDistance))")
        print("    ⏱️ 预估时间: \(String(format: "%.0f分钟", baseTime + waitTime + transferTime))")
        print("    📊 数据来源: 模拟公交数据（MapKit公交不可用）")
        
        let routes = [
            // 快速公交
            RouteInfo(
                type: .fastest,
                transportType: .publicTransport,
                distance: String(format: "%.1f公里", transitDistance),
                duration: String(format: "%.0f分钟", baseTime + waitTime + transferTime),
                price: "¥4-6",
                route: nil,
                description: "地铁+公交组合，用时较短",
                instructions: instructions,
                specialRouteType: .none,
                highlights: ["地铁换乘", "快速到达"],
                difficulty: distanceKm < 5 ? .easy : (distanceKm < 15 ? .medium : .hard)
            ),
            // 经济公交
            RouteInfo(
                type: .cheapest,
                transportType: .publicTransport,
                distance: String(format: "%.1f公里", transitDistance * 1.1),
                duration: String(format: "%.0f分钟", baseTime * 1.3 + waitTime + transferTime),
                price: "¥2-4",
                route: nil,
                description: "仅公交车，价格便宜",
                instructions: instructions,
                specialRouteType: .none,
                highlights: ["经济实惠", "直达公交"],
                difficulty: distanceKm < 5 ? .easy : (distanceKm < 15 ? .medium : .hard)
            )
        ]
        
        print("🚌 生成了\(routes.count)条模拟公交路线")
        return routes
    }
    
    // 生成模拟公交导航指令
    private func generateSimulatedTransitInstructions(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, distance: Double) -> [NavigationInstruction] {
        var instructions: [NavigationInstruction] = []
        
        let latDiff = end.latitude - start.latitude
        let lngDiff = end.longitude - start.longitude
        
        // 公交路线的典型步骤
        let steps: [(instruction: String, icon: String, distance: String)] = [
            ("步行至附近公交站", "figure.walk", "200m"),
            ("等待公交车", "bus.fill", "0m"),
            ("乘坐公交/地铁", "bus.fill", String(format: "%.1fkm", distance * 0.7)),
            ("到达换乘站", "arrow.triangle.swap", "0m"),
            ("换乘地铁/公交", "bus.fill", String(format: "%.1fkm", distance * 0.3)),
            ("步行至目的地", "figure.walk", "150m")
        ]
        
        for (index, step) in steps.enumerated() {
            let progress = Double(index) / Double(steps.count - 1)
            let coordinate = CLLocationCoordinate2D(
                latitude: start.latitude + latDiff * progress,
                longitude: start.longitude + lngDiff * progress
            )
            
            instructions.append(NavigationInstruction(
                instruction: step.instruction,
                distance: step.distance,
                icon: step.icon,
                coordinate: coordinate
            ))
        }
        
        return instructions
    }
    
    // 保留原有方法但更新逻辑
    private func generateSimulatedNormalRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType) -> [RouteInfo] {
        // 只有在非公交情况下才返回空数组
        if transportType != .publicTransport {
            print("❌ 警告：无法获取\(transportType.rawValue)的真实路线数据")
            print("   📊 数据状态：返回空数组，不提供假数据")
            return []
        }
        
        // 公交情况已经在上面处理了，这里不应该到达
        return []
    }
    
    // MARK: - 🧭 导航指令生成 (简化版)
    
    // 转向类型枚举 - 简化版
    private enum TurnDirection {
        case straight   // 直行
        case left       // 左转
        case uTurn      // 掉头
        case right      // 右转
        
        var instruction: String {
            switch self {
            case .straight: return "继续直行"
            case .left: return "向左转"
            case .uTurn: return "掉头"
            case .right: return "向右转"
            }
        }
        
        var icon: String {
            switch self {
            case .straight: return "arrow.up"
            case .left: return "arrow.turn.up.left"
            case .uTurn: return "arrow.uturn.left"
            case .right: return "arrow.turn.up.right"
            }
        }
    }
    
    // 修正后的真实路线导航指令生成方法
    private func generateNavigationInstructions(for route: MKRoute, transportType: TransportationType) -> [NavigationInstruction] {
        print("🧭 DEBUG: 开始生成真实路线导航指令")
        print("  🛣️ 路线步骤数: \(route.steps.count)")
        print("  📏 总距离: \(route.distance)米")
        print("  ⏱️ 总时间: \(route.expectedTravelTime)秒")
        
        var instructions: [NavigationInstruction] = []
        
        let steps = route.steps
        for (index, step) in steps.enumerated() {
            let instruction: String
            let icon: String
            
            print("  🧭 步骤\(index): \(step.instructions)")
            
            if index == 0 {
                instruction = "开始导航"
                icon = "location.fill"
                print("    结果: 开始导航")
            } else if index == steps.count - 1 {
                instruction = "到达目的地"
                icon = "flag.fill"
                print("    结果: 到达目的地")
            } else {
                // 优先解析MapKit提供的导航指令
                let parsedResult = parseMapKitInstruction(step.instructions)
                
                if let result = parsedResult {
                    instruction = result.instruction
                    icon = result.icon
                    print("    结果: \(instruction) (MapKit指令解析)")
                } else {
                    // 如果MapKit指令无法解析，使用几何计算
                    print("    MapKit指令无法解析，尝试几何计算...")
                    let geometricResult = calculateTurnDirectionFromStep(step, previousStep: index > 0 ? steps[index-1] : nil)
                    instruction = geometricResult.instruction
                    icon = geometricResult.icon
                    print("    结果: \(instruction) (几何计算)")
                }
            }
            
            let coordinate: CLLocationCoordinate2D
            if step.polyline.pointCount > 0 {
                let points = step.polyline.points()
                coordinate = points[0].coordinate
            } else {
                // 如果无法获取polyline坐标，使用路线的起点或终点
                coordinate = index == 0 ? route.polyline.coordinate : route.polyline.coordinate
            }
            
            let navigationInstruction = NavigationInstruction(
                instruction: instruction,
                distance: String(format: "%.0fm", step.distance),
                icon: icon,
                coordinate: coordinate
            )
            
            instructions.append(navigationInstruction)
        }
        
        print("🧭 DEBUG: 真实路线导航指令生成完成，共\(instructions.count)条指令")
        return instructions
    }
    
    // 解析MapKit指令 - 简化版
    private func parseMapKitInstruction(_ instruction: String) -> (instruction: String, icon: String)? {
        let lower = instruction.lowercased()
        
        // 掉头相关
        if lower.contains("掉头") || lower.contains("u-turn") || lower.contains("回转") {
            return ("掉头", "arrow.uturn.left")
        }
        
        // 左转相关 (包含所有左转类型)
        if lower.contains("左转") || lower.contains("turn left") ||
           lower.contains("稍向左转") || lower.contains("向左急转") ||
           lower.contains("靠左") || lower.contains("slight left") ||
           lower.contains("sharp left") || lower.contains("keep left") {
            return ("向左转", "arrow.turn.up.left")
        }
        
        // 右转相关 (包含所有右转类型)
        if lower.contains("右转") || lower.contains("turn right") ||
           lower.contains("稍向右转") || lower.contains("向右急转") ||
           lower.contains("靠右") || lower.contains("slight right") ||
           lower.contains("sharp right") || lower.contains("keep right") {
            return ("向右转", "arrow.turn.up.right")
        }
        
        // 直行相关
        if lower.contains("直行") || lower.contains("straight") ||
           lower.contains("继续") || lower.contains("continue") ||
           lower.contains("前行") || lower.contains("ahead") {
            return ("继续直行", "arrow.up")
        }
        
        // 其他特殊指令（环岛、合流、出口等）全部默认为直行
        if lower.contains("环岛") || lower.contains("roundabout") ||
           lower.contains("合流") || lower.contains("merge") || lower.contains("并线") ||
           lower.contains("出口") || lower.contains("exit") || lower.contains("驶出") {
            return ("继续直行", "arrow.up")
        }
        
        // 无法解析
        return nil
    }
    
    // 从路线step计算转向方向 - 简化版
    private func calculateTurnDirectionFromStep(_ step: MKRoute.Step, previousStep: MKRoute.Step?) -> (instruction: String, icon: String) {
        guard step.polyline.pointCount >= 2 else {
            return ("继续前进", "arrow.up")
        }
        
        let points = step.polyline.points()
        
        // 如果有前一个step，使用前一个step的结束点作为起点
        let startCoord: CLLocationCoordinate2D
        if let prevStep = previousStep, prevStep.polyline.pointCount > 0 {
            let prevPoints = prevStep.polyline.points()
            startCoord = prevPoints[prevStep.polyline.pointCount - 1].coordinate
        } else {
            startCoord = points[0].coordinate
        }
        
        // 使用当前step的中点和结束点
        let midIndex = step.polyline.pointCount / 2
        let midCoord = points[midIndex].coordinate
        let endCoord = points[step.polyline.pointCount - 1].coordinate
        
        print("      几何计算使用坐标:")
        print("        起点: (\(String(format: "%.6f", startCoord.latitude)), \(String(format: "%.6f", startCoord.longitude)))")
        print("        中点: (\(String(format: "%.6f", midCoord.latitude)), \(String(format: "%.6f", midCoord.longitude)))")
        print("        终点: (\(String(format: "%.6f", endCoord.latitude)), \(String(format: "%.6f", endCoord.longitude)))")
        
        let turnDirection = calculatePreciseTurnDirection(previous: startCoord, current: midCoord, next: endCoord)
        
        return (turnDirection.instruction, turnDirection.icon)
    }
    
    // 精确的转向计算 - 简化版
    private func calculatePreciseTurnDirection(previous: CLLocationCoordinate2D, current: CLLocationCoordinate2D, next: CLLocationCoordinate2D) -> TurnDirection {
        // 计算从前一个点到当前点的方位角
        let bearing1 = calculateGeographicBearing(from: previous, to: current)
        
        // 计算从当前点到下一个点的方位角
        let bearing2 = calculateGeographicBearing(from: current, to: next)
        
        // 计算角度变化（标准化到-180到180度之间）
        let rawAngleDiff = bearing2 - bearing1
        let angleDiff = normalizeAngle(rawAngleDiff)
        
        print("    🧭 精确转向计算:")
        print("      第一段方位角: \(String(format: "%.1f", bearing1))°")
        print("      第二段方位角: \(String(format: "%.1f", bearing2))°")
        print("      原始角度差: \(String(format: "%.1f", rawAngleDiff))°")
        print("      标准化角度差: \(String(format: "%.1f", angleDiff))°")
        
        // 根据角度差确定转向类型 - 简化为四种基本转向
        let turnDirection: TurnDirection
        let absAngle = abs(angleDiff)
        
        if absAngle < 45 {
            turnDirection = .straight
            print("      判定: 直行 (角度差 < 45°)")
        } else if absAngle < 135 {
            turnDirection = angleDiff > 0 ? .right : .left
            print("      判定: \(angleDiff > 0 ? "右转" : "左转") (45° ≤ 角度差 < 135°)")
        } else {
            turnDirection = .uTurn
            print("      判定: 掉头 (角度差 ≥ 135°)")
        }
        
        return turnDirection
    }
    
    // 计算地理方位角 - 修正版
    private func calculateGeographicBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y)
        
        // 转换为0-360度，北为0度，顺时针为正
        return fmod(bearing * 180 / .pi + 360, 360)
    }
    
    // 标准化角度到-180到180度之间
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized > 180 {
            normalized -= 360
        }
        while normalized < -180 {
            normalized += 360
        }
        return normalized
    }
}
