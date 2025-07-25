//
//  RouteService.swift
//  HelloWorld
//
//  路线计算服务
//

import Foundation
import CoreLocation
import MapKit

class RouteService {
    static let shared = RouteService()
    
    private init() {}
    
    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType, completion: @escaping ([RouteInfo]) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transportType.mkDirectionsTransportType
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response, !response.routes.isEmpty else {
                let simulatedRoutes = self.generateSimulatedRoutes(from: start, to: end, transportType: transportType)
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
                
                switch index {
                case 0:
                    routeType = .fastest
                    price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.8))" : ""
                    description = "推荐路线，路况较好，用时最短"
                case 1:
                    routeType = .shortest
                    price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.7))" : ""
                    description = "距离最短，可能有拥堵"
                default:
                    routeType = .scenic
                    price = transportType == .driving ? "¥\(Int(route.distance / 1000 * 0.9))" : ""
                    description = "风景路线，沿途景色优美"
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
                    instructions: instructions
                )
                
                routeInfos.append(routeInfo)
            }
            
            completion(routeInfos)
        }
    }
    
    private func generateSimulatedRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, transportType: TransportationType) -> [RouteInfo] {
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        
        let distanceKm = distance / 1000
        let baseTime = max(distanceKm * (transportType == .walking ? 12 : transportType == .driving ? 2 : 4), 10)
        
        let instructions = generateSimulatedInstructions(from: start, to: end, transportType: transportType)
        
        return [
            RouteInfo(
                type: .fastest,
                transportType: transportType,
                distance: String(format: "%.1f公里", distanceKm),
                duration: String(format: "%.0f分钟", baseTime),
                price: transportType == .driving ? "¥\(Int(distanceKm * 0.8))" : (transportType == .publicTransport ? "¥3-8" : ""),
                route: nil,
                description: "推荐路线",
                instructions: instructions
            )
        ]
    }
    
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
