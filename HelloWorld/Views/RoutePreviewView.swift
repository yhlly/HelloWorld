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
    let onPreviewTapped: () -> Void
    let onPlayTapped: () -> Void
    
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
                
                // 新的导航按钮
                HStack(spacing: 12) {
                    Button("Preview") {
                        onPreviewTapped()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Play") {
                        onPlayTapped()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
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
