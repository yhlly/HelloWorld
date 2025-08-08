//
//  CollectibleMapOverlay.swift
//  HelloWorld
//
//  地图收集点叠加层组件 - 修复版本
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

// 地图收集点叠加视图
struct CollectibleMapOverlay: View {
    let collectionManager: CollectionManager
    let userLocation: CLLocationCoordinate2D?
    let onCollectibleTapped: (CollectiblePoint) -> Void
    
    private var collectiblesInRange: [CollectiblePoint] {
        guard let userLocation = userLocation else { return [] }
        return collectionManager.collectiblesInRange(of: userLocation)
    }
    
    var body: some View {
        ZStack {
            // 在地图上显示收集点
            ForEach(collectiblesInRange, id: \.id) { collectible in
                CollectibleMapPin(
                    collectible: collectible,
                    onTapped: {
                        onCollectibleTapped(collectible)
                    }
                )
            }
        }
    }
}

// 地图收集点图钉
struct CollectibleMapPin: View {
    let collectible: CollectiblePoint
    let onTapped: () -> Void
    
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Button(action: onTapped) {
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(collectibleColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                
                // 主要图标
                Circle()
                    .fill(collectibleColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: collectibleIcon)
                            .font(.title3)
                            .foregroundColor(.white)
                    )
                
                // 收集指示器
                if !collectible.isCollected {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 40, height: 40)
                }
            }
        }
        .disabled(collectible.isCollected)
        .opacity(collectible.isCollected ? 0.5 : 1.0)
        .onAppear {
            // 启动脉动动画
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var collectibleColor: Color {
        switch collectible.category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
    
    private var collectibleIcon: String {
        switch collectible.category {
        case .food:
            return "fork.knife"
        case .scenic:
            return "mountain.2"
        case .attraction:
            return "camera"
        case .landmark:
            return "building.2"
        case .culture:
            return "book"
        }
    }
}

// 收集点信息弹窗
struct CollectibleInfoPopup: View {
    let collectible: CollectiblePoint
    let onCollect: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部图标和名称
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(popupColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: collectible.category.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(popupColor)
                }
                
                Text(collectible.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(collectible.category.rawValue)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(popupColor.opacity(0.2))
                    )
                    .foregroundColor(popupColor)
            }
            
            // 描述
            Text(collectible.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // 按钮
            HStack(spacing: 16) {
                Button("取消") {
                    onDismiss()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary, lineWidth: 1)
                )
                
                Button(collectible.isCollected ? "已收集" : "收集") {
                    if !collectible.isCollected {
                        onCollect()
                    }
                    onDismiss()
                }
                .disabled(collectible.isCollected)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(collectible.isCollected ? Color.gray : popupColor)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
        .padding(.horizontal, 40)
    }
    
    private var popupColor: Color {
        switch collectible.category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

// 收集点距离指示器
struct CollectibleDistanceIndicator: View {
    let collectibles: [CollectiblePoint]
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        if let nearest = nearestCollectible, nearest.distance <= 100 {
            HStack(spacing: 8) {
                Image(systemName: nearest.collectible.category.iconName)
                    .foregroundColor(indicatorColor)
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(nearest.collectible.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("\(Int(nearest.distance))米")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private var nearestCollectible: (collectible: CollectiblePoint, distance: Double)? {
        guard let userLocation = userLocation else { return nil }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        let collectibleDistances: [(collectible: CollectiblePoint, distance: Double)] = collectibles
            .filter { !$0.isCollected }
            .compactMap { collectible in
                let collectibleLocation = CLLocation(latitude: collectible.coordinate.latitude, longitude: collectible.coordinate.longitude)
                let distance = userCLLocation.distance(from: collectibleLocation)
                return (collectible: collectible, distance: distance)
            }
        
        return collectibleDistances.min { $0.distance < $1.distance }
    }
    
    private var indicatorColor: Color {
        guard let nearest = nearestCollectible else { return .gray }
        
        switch nearest.collectible.category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    CollectibleMapOverlayPreview()
}

private struct CollectibleMapOverlayPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("收集点组件预览")
                .font(.headline)
                .padding()
            
            // 显示收集点信息
            VStack(alignment: .leading, spacing: 8) {
                Text("示例收集点:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(sampleCollectibles, id: \.id) { collectible in
                    HStack {
                        Image(systemName: collectible.category.iconName)
                            .foregroundColor(getColorForCategory(collectible.category))
                        Text(collectible.name)
                            .font(.caption)
                        Spacer()
                        Text(collectible.category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(getColorForCategory(collectible.category).opacity(0.2))
                            )
                            .foregroundColor(getColorForCategory(collectible.category))
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 距离指示器预览
            CollectibleDistanceIndicator(
                collectibles: sampleCollectibles,
                userLocation: sampleUserLocation
            )
            .padding(.horizontal)
            
            Spacer()
            
            Text("注意：完整功能需要在实际应用中使用CollectionManager")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    private var sampleCollectibles: [CollectiblePoint] {
        return [
            CollectiblePoint(
                name: "特色小吃店",
                category: .food,
                coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
            ),
            CollectiblePoint(
                name: "颐和园美景",
                category: .scenic,
                coordinate: CLLocationCoordinate2D(latitude: 39.9052, longitude: 116.4084)
            ),
            CollectiblePoint(
                name: "故宫博物院",
                category: .attraction,
                coordinate: CLLocationCoordinate2D(latitude: 39.9062, longitude: 116.4094)
            )
        ]
    }
    
    private var sampleUserLocation: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
    }
    
    private func getColorForCategory(_ category: CollectibleCategory) -> Color {
        switch category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}
