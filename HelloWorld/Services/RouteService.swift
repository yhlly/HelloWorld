//
//  RouteService.swift
//  HelloWorld
//
//  路线计算服务 - 支持特殊路线类型
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
    
    // 新增：支持特殊路线的路线计算方法
    func calculateRouteWithSpecialType(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, specialConfig: SpecialRouteConfig, completion: @escaping ([RouteInfo]) -> Void) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transportType.mkDirectionsTransportType
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response, !response.routes.isEmpty else {
                // 如果无法获取真实路线，生成模拟路线
                let simulatedRoutes = self.generateSimulatedRoutesWithSpecialType(
                    from: start,
                    to: end,
                    transportType: transportType,
                    specialConfig: specialConfig
                )
                completion(simulatedRoutes)
                return
            }
            
            var routeInfos: [RouteInfo] = []
            
            for (index, route) in response.routes.enumerated() {
                let distance = String(format: "%.1f公里", route.distance / 1000)
                let duration = String(format: "%.0f分钟", route.expectedTravelTime / 60)
                
                let routeType: RouteType
                let price: String
                let description: String
                let highlights: [String]
                let difficulty: RouteDifficulty
                
                switch index {
                case 0:
                    routeType = specialConfig.specialType == .none ? .fastest : .recommended
                    price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.8))" : ""
                    (description, highlights, difficulty) = self.generateSpecialRouteInfo(
                        for: specialConfig.specialType,
                        distance: route.distance,
                        transportType: transportType,
                        isPrimary: true
                    )
                case 1:
                    routeType = .alternative
                    price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.7))" : ""
                    (description, highlights, difficulty) = self.generateSpecialRouteInfo(
                        for: specialConfig.specialType,
                        distance: route.distance,
                        transportType: transportType,
                        isPrimary: false
                    )
                default:
                    routeType = .scenic
                    price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.9))" : ""
                    (description, highlights, difficulty) = self.generateSpecialRouteInfo(
                        for: specialConfig.specialType,
                        distance: route.distance,
                        transportType: transportType,
                        isPrimary: false
                    )
                }
                
                let instructions = self.generateNavigationInstructions(for: route, transportType: transportType)
                
                let routeInfo = RouteInfo(
                    type: routeType,
                    transportType: transportType,
                    distance: distance,
                    duration: duration,
                    price: price,
                    route: route,
                    description: description,
                    instructions: instructions,
                    specialRouteType: specialConfig.specialType,
                    highlights: highlights,
                    difficulty: difficulty
                )
                
                routeInfos.append(routeInfo)
            }
            
            completion(routeInfos)
        }
    }
    
    // 生成模拟特殊路线
    private func generateSimulatedRoutesWithSpecialType(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, specialConfig: SpecialRouteConfig) -> [RouteInfo] {
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        
        let distanceKm = distance / 1000
        let baseTime = max(distanceKm * (transportType == .walking ? 12 : transportType == .driving ? 2 : 4), 10)
        
        let instructions = generateSimulatedInstructions(from: start, to: end, transportType: transportType)
        
        var routes: [RouteInfo] = []
        
        // 根据特殊路线类型生成不同的路线选项
        if specialConfig.specialType == .none {
            // 常规路线：最快、最短、最便宜
            routes = [
                createSimulatedRoute(
                    type: .fastest,
                    transportType: transportType,
                    baseDistance: distanceKm,
                    baseTime: baseTime,
                    multiplier: 1.0,
                    instructions: instructions,
                    specialConfig: specialConfig
                ),
                createSimulatedRoute(
                    type: .shortest,
                    transportType: transportType,
                    baseDistance: distanceKm,
                    baseTime: baseTime,
                    multiplier: 0.9,
                    instructions: instructions,
                    specialConfig: specialConfig
                ),
                createSimulatedRoute(
                    type: .cheapest,
                    transportType: transportType,
                    baseDistance: distanceKm,
                    baseTime: baseTime,
                    multiplier: 1.1,
                    instructions: instructions,
                    specialConfig: specialConfig
                )
            ]
        } else {
            // 特殊路线：推荐路线、替代路线
            routes = [
                createSimulatedRoute(
                    type: .recommended,
                    transportType: transportType,
                    baseDistance: distanceKm,
                    baseTime: baseTime,
                    multiplier: 1.0 + specialConfig.maxDetourPercentage / 100,
                    instructions: instructions,
                    specialConfig: specialConfig
                ),
                createSimulatedRoute(
                    type: .alternative,
                    transportType: transportType,
                    baseDistance: distanceKm,
                    baseTime: baseTime,
                    multiplier: 1.1 + specialConfig.maxDetourPercentage / 100,
                    instructions: instructions,
                    specialConfig: specialConfig
                )
            ]
        }
        
        return routes
    }
    
    // 创建模拟路线
    private func createSimulatedRoute(
        type: RouteType,
        transportType: TransportationType,
        baseDistance: Double,
        baseTime: Double,
        multiplier: Double,
        instructions: [NavigationInstruction],
        specialConfig: SpecialRouteConfig
    ) -> RouteInfo {
        let adjustedDistance = baseDistance * multiplier
        let adjustedTime = baseTime * multiplier
        
        let (description, highlights, difficulty) = generateSpecialRouteInfo(
            for: specialConfig.specialType,
            distance: adjustedDistance * 1000,
            transportType: transportType,
            isPrimary: type == .recommended || type == .fastest
        )
        
        return RouteInfo(
            type: type,
            transportType: transportType,
            distance: String(format: "%.1f公里", adjustedDistance),
            duration: String(format: "%.0f分钟", adjustedTime),
            price: transportType == .driving ? "¥\(Int(adjustedDistance * 0.8))" : (transportType == .publicTransport ? "¥3-8" : ""),
            route: nil,
            description: description,
            instructions: instructions,
            specialRouteType: specialConfig.specialType,
            highlights: highlights,
            difficulty: difficulty
        )
    }
    
    // 生成特殊路线信息
    private func generateSpecialRouteInfo(for specialType: SpecialRouteType, distance: Double, transportType: TransportationType, isPrimary: Bool) -> (description: String, highlights: [String], difficulty: RouteDifficulty) {
        
        let distanceKm = distance / 1000
        let difficulty: RouteDifficulty = distanceKm < 5 ? .easy : (distanceKm < 15 ? .medium : .hard)
        
        switch specialType {
        case .none:
            return (
                description: isPrimary ? "推荐路线，路况较好，用时最短" : "备选路线，可能有轻微拥堵",
                highlights: ["高效出行", "路况良好"],
                difficulty: difficulty
            )
            
        case .scenic:
            return (
                description: isPrimary ? "风景优美路线，途径多个观景点" : "风景替代路线，沿途有公园绿地",
                highlights: isPrimary ? ["湖滨公园", "观景台", "河滨步道"] : ["城市绿地", "小型公园"],
                difficulty: difficulty
            )
            
        case .food:
            return (
                description: isPrimary ? "美食路线，途径知名餐厅和小吃街" : "美食替代路线，路过本地特色小店",
                highlights: isPrimary ? ["老字号餐厅", "美食街", "网红咖啡"] : ["本地小吃", "特色茶楼"],
                difficulty: difficulty
            )
            
        case .attractions:
            return (
                description: isPrimary ? "观光路线，经过主要景点和地标" : "景点替代路线，途径文化古迹",
                highlights: isPrimary ? ["历史博物馆", "地标建筑", "文化广场"] : ["古建筑", "纪念碑"],
                difficulty: difficulty
            )
            
        case .shopping:
            return (
                description: isPrimary ? "购物路线，途径大型商场和购物中心" : "购物替代路线，经过特色商业街",
                highlights: isPrimary ? ["购物中心", "奢侈品店", "百货大楼"] : ["商业街", "特色小店"],
                difficulty: difficulty
            )
            
        case .cultural:
            return (
                description: isPrimary ? "文化路线，经过博物馆和艺术场所" : "文化替代路线，途径历史文化区",
                highlights: isPrimary ? ["艺术博物馆", "剧院", "图书馆"] : ["文化街区", "古建筑群"],
                difficulty: difficulty
            )
            
        case .nature:
            return (
                description: isPrimary ? "自然路线，远离城市喧嚣，环境清幽" : "自然替代路线，经过小型绿地",
                highlights: isPrimary ? ["森林公园", "湿地", "植物园"] : ["社区绿地", "小花园"],
                difficulty: difficulty
            )
            
        case .nightlife:
            return (
                description: isPrimary ? "夜生活路线，途径酒吧和娱乐场所" : "夜生活替代路线，经过夜市区域",
                highlights: isPrimary ? ["酒吧街", "夜店", "KTV"] : ["夜市", "24小时餐厅"],
                difficulty: difficulty
            )
        }
    }
    
    // 原有的导航指令生成方法
    private func generateNavigationInstructions(for route: MKRoute, transportType: TransportationType) -> [NavigationInstruction] {
        var instructions: [NavigationInstruction] = []
        
        let steps = route.steps
        for (index, step) in steps.enumerated() {
            let instruction: String
            let icon: String
            
            if index == 0 {
                instruction = "开始导航"
                icon = "location.fill"
            } else if index == steps.count - 1 {
                instruction = "到达目的地"
                icon = "flag.fill"
            } else {
                if step.instructions.contains("左转") || step.instructions.contains("左") {
                    instruction = "向左转"
                    icon = "arrow.turn.up.left"
                } else if step.instructions.contains("右转") || step.instructions.contains("右") {
                    instruction = "向右转"
                    icon = "arrow.turn.up.right"
                } else if step.instructions.contains("直行") || step.instructions.contains("继续") {
                    instruction = "继续直行"
                    icon = "arrow.up"
                } else {
                    instruction = step.instructions.isEmpty ? "继续前进" : step.instructions
                    icon = "arrow.up"
                }
            }
            
            let coordinate: CLLocationCoordinate2D
            if step.polyline.pointCount > 0 {
                let points = step.polyline.points()
                coordinate = points[0].coordinate
            } else {
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
        
        return instructions
    }
    
    // 原有的模拟导航指令生成方法
    private func generateSimulatedInstructions(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType) -> [NavigationInstruction] {
        var instructions: [NavigationInstruction] = []
        
        let latDiff = end.latitude - start.latitude
        let lngDiff = end.longitude - start.longitude
        let steps = 8
        
        for i in 0..<steps {
            let progress = Double(i) / Double(steps - 1)
            let coordinate = CLLocationCoordinate2D(
                latitude: start.latitude + latDiff * progress,
                longitude: start.longitude + lngDiff * progress
            )
            
            let instruction: String
            let icon: String
            let distance: String
            
            switch i {
            case 0:
                instruction = "开始导航"
                icon = "location.fill"
                distance = "0m"
            case 1:
                instruction = "继续直行"
                icon = "arrow.up"
                distance = "200m"
            case 2:
                instruction = "向右转"
                icon = "arrow.turn.up.right"
                distance = "150m"
            case 3:
                instruction = "继续直行"
                icon = "arrow.up"
                distance = "300m"
            case 4:
                instruction = "向左转"
                icon = "arrow.turn.up.left"
                distance = "100m"
            case 5:
                instruction = "继续直行"
                icon = "arrow.up"
                distance = "250m"
            case 6:
                instruction = "向右转"
                icon = "arrow.turn.up.right"
                distance = "80m"
            case 7:
                instruction = "到达目的地"
                icon = "flag.fill"
                distance = "50m"
            default:
                instruction = "继续前进"
                icon = "arrow.up"
                distance = "100m"
            }
            
            instructions.append(NavigationInstruction(
                instruction: instruction,
                distance: distance,
                icon: icon,
                coordinate: coordinate
            ))
        }
        
        return instructions
    }
}
