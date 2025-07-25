//
//  Map3DNavigationView.swift
//  HelloWorld
//
//  3D地图导航视图
//

import SwiftUI
import MapKit

struct Map3DNavigationView: View {
    let selectedRoute: RouteInfo?
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @Binding var currentLocationIndex: Int
    
    let onBackTapped: () -> Void
    let onStartNavigationTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部控制栏
            HStack {
                Button("返回") {
                    onBackTapped()
                }
                
                Spacer()
                
                Text("3D 地图导航")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("开始导航") {
                    onStartNavigationTapped()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 3D地图
            if let route = selectedRoute {
                Map3DView(
                    region: $region,
                    route: route.route,
                    startCoordinate: $startCoordinate,
                    endCoordinate: $endCoordinate,
                    currentLocationIndex: $currentLocationIndex,
                    instructions: route.instructions
                )
                .allowsHitTesting(false)
            }
            
            // 底部导航指令
            if let route = selectedRoute, currentLocationIndex < route.instructions.count {
                let instruction = route.instructions[currentLocationIndex]
                
                HStack {
                    Image(systemName: instruction.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(instruction.instruction)
                            .font(.headline)
                        Text("在 \(instruction.distance) 处")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            if currentLocationIndex > 0 {
                                currentLocationIndex -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                        
                        Text("\(currentLocationIndex + 1)/\(route.instructions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            if currentLocationIndex < route.instructions.count - 1 {
                                currentLocationIndex += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
        }
    }
}
