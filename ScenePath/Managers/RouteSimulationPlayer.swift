//
//  RouteSimulationPlayer.swift
//  ScenePath
//
//  路线模拟播放器 - 支持逐步沿路线前进
//

import Foundation
import MapKit
import CoreLocation
import SwiftUI

// 路线模拟播放器 - 允许用户按钮模拟行进
class RouteSimulationPlayer: ObservableObject {
    // 路线数据
    private var route: MKRoute?
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    
    // 当前位置信息
    @Published var currentIndex: Int = 0
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentHeading: Double = 0
    @Published var isPlaying: Bool = false
    
    // 自动播放定时器
    private var playTimer: Timer?
    private var stepDistance: Double = 20 // 每步移动20米
    
    // 状态回调
    var onPositionChanged: ((CLLocationCoordinate2D, Int) -> Void)?
    
    init() {}
    
    // 加载路线
    func loadRoute(_ route: MKRoute) {
        self.route = route
        extractRouteCoordinates()
        reset()
    }
    
    // 提取路线上的坐标点
    private func extractRouteCoordinates() {
        guard let route = route else { return }
        
        var coordinates: [CLLocationCoordinate2D] = []
        let pointCount = route.polyline.pointCount
        let points = route.polyline.points()
        
        // 提取所有路线点
        for i in 0..<pointCount {
            coordinates.append(points[i].coordinate)
        }
        
        // 平滑处理路线，确保点之间的距离合理
        routeCoordinates = smoothAndResamplePath(coordinates, desiredSpacing: stepDistance)
        
        print("🚶 路线模拟器: 加载了\(routeCoordinates.count)个路线点")
    }
    
    // 重置到起点
    func reset() {
        currentIndex = 0
        isPlaying = false
        playTimer?.invalidate()
        playTimer = nil
        
        if !routeCoordinates.isEmpty {
            currentLocation = routeCoordinates.first
            if routeCoordinates.count > 1 {
                // 计算初始朝向
                let nextPoint = routeCoordinates[1]
                currentHeading = calculateHeading(from: currentLocation!, to: nextPoint)
            }
            notifyPositionChanged()
        }
    }
    
    // 向前移动一步
    func stepForward() {
        guard !routeCoordinates.isEmpty else { return }
        
        // 已经到达终点
        if currentIndex >= routeCoordinates.count - 1 {
            print("🚶 路线模拟器: 已到达终点")
            return
        }
        
        // 移动到下一个点
        currentIndex += 1
        currentLocation = routeCoordinates[currentIndex]
        
        // 计算朝向（如果不是最后一个点）
        if currentIndex < routeCoordinates.count - 1 {
            let nextPoint = routeCoordinates[currentIndex + 1]
            currentHeading = calculateHeading(from: currentLocation!, to: nextPoint)
        }
        
        // 通知位置变化
        notifyPositionChanged()
        
        print("🚶 路线模拟器: 前进到点\(currentIndex)/\(routeCoordinates.count-1)")
    }
    
    // 向后移动一步
    func stepBackward() {
        guard !routeCoordinates.isEmpty else { return }
        
        // 已经在起点
        if currentIndex <= 0 {
            print("🚶 路线模拟器: 已在起点")
            return
        }
        
        // 移动到前一个点
        currentIndex -= 1
        currentLocation = routeCoordinates[currentIndex]
        
        // 计算朝向
        if currentIndex < routeCoordinates.count - 1 {
            let nextPoint = routeCoordinates[currentIndex + 1]
            currentHeading = calculateHeading(from: currentLocation!, to: nextPoint)
        }
        
        // 通知位置变化
        notifyPositionChanged()
        
        print("🚶 路线模拟器: 后退到点\(currentIndex)/\(routeCoordinates.count-1)")
    }
    
    // 开始自动播放
    func startPlaying(speed: Double = 1.0) {
        guard !routeCoordinates.isEmpty && currentIndex < routeCoordinates.count - 1 else { return }
        
        isPlaying = true
        
        // 根据速度决定间隔时间（速度越大，间隔越小）
        let interval = 1.0 / speed
        
        playTimer?.invalidate()
        playTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            if self.currentIndex < self.routeCoordinates.count - 1 {
                self.stepForward()
            } else {
                self.stopPlaying()
            }
        }
        
        print("🚶 路线模拟器: 开始自动播放，速度\(speed)x")
    }
    
    // 停止自动播放
    func stopPlaying() {
        isPlaying = false
        playTimer?.invalidate()
        playTimer = nil
        print("🚶 路线模拟器: 停止自动播放")
    }
    
    // 获取完成百分比
    func getCompletionPercentage() -> Double {
        guard !routeCoordinates.isEmpty else { return 0 }
        return Double(currentIndex) / Double(routeCoordinates.count - 1)
    }
    
    // 获取剩余距离（米）
    func getRemainingDistance() -> Double {
        guard !routeCoordinates.isEmpty, currentIndex < routeCoordinates.count else { return 0 }
        
        var distance: Double = 0
        for i in currentIndex..<(routeCoordinates.count - 1) {
            let currentPoint = routeCoordinates[i]
            let nextPoint = routeCoordinates[i + 1]
            
            let currentLocation = CLLocation(latitude: currentPoint.latitude, longitude: currentPoint.longitude)
            let nextLocation = CLLocation(latitude: nextPoint.latitude, longitude: nextPoint.longitude)
            
            distance += currentLocation.distance(from: nextLocation)
        }
        
        return distance
    }
    
    // 获取预计剩余时间（秒）- 基于平均速度
    func getEstimatedRemainingTime(averageSpeed: Double = 5.0) -> Double {
        let remainingDistance = getRemainingDistance()
        return remainingDistance / averageSpeed // 秒
    }
    
    // 通知位置变化
    private func notifyPositionChanged() {
        if let location = currentLocation {
            onPositionChanged?(location, currentIndex)
        }
    }
    
    // MARK: - 辅助方法
    
    // 计算两点之间的朝向角度（0-360度，北为0，顺时针）
    private func calculateHeading(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        // 转换为角度并确保在0-360范围内
        var degreesBearing = radiansBearing * 180 / .pi
        while degreesBearing < 0 {
            degreesBearing += 360
        }
        
        return degreesBearing
    }
    
    // 平滑并重新采样路径，确保点之间的距离接近期望值
    private func smoothAndResamplePath(_ originalPoints: [CLLocationCoordinate2D], desiredSpacing: Double) -> [CLLocationCoordinate2D] {
        guard originalPoints.count >= 2 else { return originalPoints }
        
        var result: [CLLocationCoordinate2D] = []
        result.append(originalPoints.first!) // 添加起点
        
        var totalDistance: Double = 0
        var accumulatedDistance: Double = 0
        
        // 计算总距离并找出需要采样的位置
        for i in 0..<(originalPoints.count - 1) {
            let startLocation = CLLocation(
                latitude: originalPoints[i].latitude,
                longitude: originalPoints[i].longitude
            )
            let endLocation = CLLocation(
                latitude: originalPoints[i + 1].latitude,
                longitude: originalPoints[i + 1].longitude
            )
            
            let segmentDistance = startLocation.distance(from: endLocation)
            totalDistance += segmentDistance
            
            // 在这段距离内需要采样几个点
            let segmentSteps = max(1, Int(segmentDistance / desiredSpacing))
            
            // 添加采样点（除了最后一个点，它会在循环后面添加）
            if segmentSteps > 1 {
                for step in 1..<segmentSteps {
                    let fraction = Double(step) / Double(segmentSteps)
                    let interpolatedLat = originalPoints[i].latitude +
                        (originalPoints[i + 1].latitude - originalPoints[i].latitude) * fraction
                    let interpolatedLng = originalPoints[i].longitude +
                        (originalPoints[i + 1].longitude - originalPoints[i].longitude) * fraction
                    
                    result.append(CLLocationCoordinate2D(
                        latitude: interpolatedLat,
                        longitude: interpolatedLng
                    ))
                }
            }
            
            // 如果是最后一段，添加终点
            if i == originalPoints.count - 2 {
                result.append(originalPoints.last!)
            }
        }
        
        return result
    }
}

// 路线播放控制器 UI 组件
struct RoutePlayerControls: View {
    @ObservedObject var player: RouteSimulationPlayer
    var onComplete: (() -> Void)?
    
    @State private var showingSpeedMenu = false
    @State private var selectedSpeed: Double = 1.0
    
    var body: some View {
        VStack(spacing: 12) {
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // 进度
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(player.getCompletionPercentage()), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            
            // 控制按钮
            HStack(spacing: 20) {
                // 后退按钮
                Button(action: {
                    player.stepBackward()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.8))
                        )
                }
                
                // 播放/暂停按钮
                Button(action: {
                    if player.isPlaying {
                        player.stopPlaying()
                    } else {
                        player.startPlaying(speed: selectedSpeed)
                    }
                }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(player.isPlaying ? Color.orange : Color.green)
                        )
                }
                
                // 前进按钮
                Button(action: {
                    player.stepForward()
                }) {
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.8))
                        )
                }
            }
            .padding(.horizontal, 30)
            
            // 速度选择按钮
            Button(action: {
                showingSpeedMenu.toggle()
            }) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.blue)
                    Text("\(String(format: "%.1f", selectedSpeed))x")
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
            }
            .actionSheet(isPresented: $showingSpeedMenu) {
                ActionSheet(
                    title: Text("选择播放速度"),
                    buttons: [
                        .default(Text("0.5x")) { selectedSpeed = 0.5 },
                        .default(Text("1.0x")) { selectedSpeed = 1.0 },
                        .default(Text("1.5x")) { selectedSpeed = 1.5 },
                        .default(Text("2.0x")) { selectedSpeed = 2.0 },
                        .cancel()
                    ]
                )
            }
        }
    }
}
