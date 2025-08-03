//
//  RoutePreviewView.swift
//  HelloWorld
//
//  路线预览界面
//

import SwiftUI
import MapKit

struct RoutePreviewView: View {
    let selectedRoute: RouteInfo?
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    
    let onBackTapped: () -> Void
    let onPlayTapped: () -> Void
    let onSimulateTapped: () -> Void // 路线模拟回调
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部信息栏
            HStack {
                Button("返回") {
                    onBackTapped()
                }
                
                Spacer()
                
                if let route = selectedRoute {
                    VStack {
                        Text(route.type.rawValue)
                            .font(.headline)
                        HStack {
                            Image(systemName: route.transportType.icon)
                            Text(route.duration)
                            Text(route.distance)
                            if !route.price.isEmpty {
                                Text(route.price)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 导航按钮组
                HStack(spacing: 8) {
                    // 模拟按钮
                    Button("模拟行走") {
                        onSimulateTapped()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
                    
                    // AR导航按钮
                    Button("AR导航") {
                        onPlayTapped()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 地图
            MapViewRepresentable(
                region: $region,
                route: selectedRoute?.route,
                startCoordinate: $startCoordinate,
                endCoordinate: $endCoordinate
            )
            .allowsHitTesting(false)
        }
    }
}
