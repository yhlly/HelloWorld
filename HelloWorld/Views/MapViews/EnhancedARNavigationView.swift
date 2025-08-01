//
//  FixedARNavigationView.swift
//  HelloWorld
//
//  修复后的AR导航视图 - 确保有清晰的路线指引
//

import SwiftUI
import ARKit
import SceneKit
import MapKit
import SwiftData

// 修复后的AR导航视图
struct EnhancedARNavigationView: View {
    let route: RouteInfo
    @Binding var currentLocationIndex: Int
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    
    let collectionManager: CollectionManager
    let onBackTapped: () -> Void
    
    @State private var isNavigating = false
    @State private var currentSpeed = "0"
    @State private var remainingTime = ""
    @State private var remainingDistance = ""
    @State private var timer: Timer?
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var showingCollection = false
    @State private var showingCollectionSuccess = false
    @State private var lastCollectedItem: String = ""
    @State private var showingCollectiblePopup = false
    @State private var selectedCollectible: CollectiblePoint?
    @State private var debugInfo = "AR导航启动中..."
    
    // AR相关状态
    @State private var arSessionStatus = "检查AR支持..."
    @State private var showARContent = true
    
    private var currentInstruction: NavigationInstruction? {
        guard currentLocationIndex < route.instructions.count else { return nil }
        return route.instructions[currentLocationIndex]
    }
    
    private var collectiblesInRange: [CollectiblePoint] {
        guard let userLocation = userLocation else { return [] }
        let collectibles = collectionManager.collectiblesInRange(of: userLocation)
        return collectibles
    }
    
    var body: some View {
        ZStack {
            // AR场景或备用视图
            if ARWorldTrackingConfiguration.isSupported && showARContent {
                EnhancedARSceneViewWithGuides(
                    currentInstruction: .constant(currentInstruction),
                    isNavigating: $isNavigating,
                    userLocation: $userLocation,
                    arSessionStatus: $arSessionStatus, collectionManager: collectionManager,
                    route: route,
                    onCollectionTapped: { collectible in
                        handleCollectionTapped(collectible)
                    }
                )
                .ignoresSafeArea()
            } else {
                // AR不支持时的备用导航界面
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        Image(systemName: "camera.metering.unknown")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("AR不可用")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        Text("使用传统导航模式")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // 传统导航指令显示
                        if let instruction = currentInstruction {
                            VStack(spacing: 12) {
                                Image(systemName: instruction.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                
                                Text(instruction.instruction)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("在 \(instruction.distance) 处")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                            .padding(.top, 20)
                        }
                    }
                }
            }
            
            // UI叠加层
            VStack {
                // 顶部状态栏
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // 当前指令快速显示
                        if let instruction = currentInstruction {
                            HStack {
                                Image(systemName: instruction.icon)
                                    .foregroundColor(.blue)
                                Text(instruction.instruction)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .font(.headline)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.white.opacity(0.8))
                            Text(remainingTime)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            
                            Image(systemName: "location")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 8)
                            Text(remainingDistance)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .font(.callout)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // AR状态指示
                        Text(arSessionStatus)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // 收集统计按钮
                        Button(action: {
                            showingCollection = true
                        }) {
                            HStack {
                                Image(systemName: "bag")
                                    .foregroundColor(.white)
                                Text("\(collectionManager.getCollectionStats().total)")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                Spacer()
                
                // 中间区域：大号导航指令（确保用户能看到）
                if let instruction = currentInstruction {
                    VStack(spacing: 16) {
                        // 大号方向箭头
                        Image(systemName: instruction.icon)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 120, height: 120)
                            )
                            .shadow(color: .blue.opacity(0.5), radius: 10)
                        
                        // 指令文字
                        VStack(spacing: 8) {
                            Text(instruction.instruction)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("在 \(instruction.distance) 处")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // 进度指示
                        HStack {
                            ForEach(0..<min(route.instructions.count, 10), id: \.self) { index in
                                Circle()
                                    .fill(index == currentLocationIndex ? Color.blue : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                            
                            if route.instructions.count > 10 {
                                Text("...")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.caption)
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
                
                Spacer()
                
                // 收集点距离指示器
                if !collectiblesInRange.isEmpty {
                    CollectibleDistanceIndicator(
                        collectibles: collectiblesInRange,
                        userLocation: userLocation
                    )
                    .padding(.horizontal)
                }
                
                // Debug信息
                if !debugInfo.isEmpty {
                    Text(debugInfo)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal)
                }
                
                // 底部控制栏
                HStack(spacing: 20) {
                    // 返回按钮
                    Button(action: {
                        onBackTapped()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red, lineWidth: 2)
                                    )
                            )
                    }
                    
                    // 上一步
                    Button(action: {
                        if currentLocationIndex > 0 {
                            withAnimation(.spring()) {
                                currentLocationIndex -= 1
                            }
                            updateNavigationInfo()
                            updateUserLocation()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            )
                    }
                    .disabled(currentLocationIndex <= 0)
                    .opacity(currentLocationIndex <= 0 ? 0.5 : 1.0)
                    
                    // 播放/暂停
                    Button(action: {
                        withAnimation(.spring()) {
                            isNavigating.toggle()
                        }
                        
                        if isNavigating {
                            startNavigationTimer()
                        } else {
                            stopNavigationTimer()
                        }
                        updateDebugInfo()
                    }) {
                        Image(systemName: isNavigating ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(
                                Circle()
                                    .fill(isNavigating ? Color.orange : Color.green)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                    )
                            )
                    }
                    
                    // 下一步
                    Button(action: {
                        if currentLocationIndex < route.instructions.count - 1 {
                            withAnimation(.spring()) {
                                currentLocationIndex += 1
                            }
                            updateNavigationInfo()
                            updateUserLocation()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            )
                    }
                    .disabled(currentLocationIndex >= route.instructions.count - 1)
                    .opacity(currentLocationIndex >= route.instructions.count - 1 ? 0.5 : 1.0)
                    
                    // AR开关按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            showARContent.toggle()
                        }
                        updateDebugInfo()
                    }) {
                        Image(systemName: showARContent ? "arkit" : "map")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(showARContent ? Color.blue : Color.gray, lineWidth: 2)
                                    )
                            )
                    }
                }
                .padding(.bottom, 50)
            }
            
            // 收集成功提示
            if showingCollectionSuccess {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        Text("收集成功：\(lastCollectedItem)")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.bottom, 200)
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingCollection) {
            CollectionView(collectionManager: collectionManager)
        }
        .sheet(isPresented: $showingCollectiblePopup) {
            if let collectible = selectedCollectible {
                CollectibleInfoSheet(
                    collectible: collectible,
                    onCollect: {
                        handleCollectionTapped(collectible)
                        showingCollectiblePopup = false
                    },
                    onDismiss: {
                        showingCollectiblePopup = false
                    }
                )
                .presentationDetents([.height(300)])
            }
        }
        .onAppear {
            print("🎯 DEBUG: FixedARNavigationView onAppear")
            setupCollectionManager()
            updateNavigationInfo()
            updateUserLocation()
            updateDebugInfo()
        }
        .onDisappear {
            print("🎯 DEBUG: FixedARNavigationView onDisappear")
            stopNavigationTimer()
        }
    }
    
    // MARK: - 辅助方法
    
    private func setupCollectionManager() {
        print("🎯 DEBUG: setupCollectionManager 开始")
        collectionManager.generateCollectiblePoints(for: route.specialRouteType, instructions: route.instructions)
    }
    
    private func updateUserLocation() {
        if let currentInstruction = currentInstruction {
            userLocation = currentInstruction.coordinate
            collectionManager.updateLocation(currentInstruction.coordinate)
            
            print("🎯 DEBUG: 用户位置更新到指令\(currentLocationIndex + 1)")
        }
    }
    
    private func handleCollectionTapped(_ collectible: CollectiblePoint) {
        print("🎯 DEBUG: handleCollectionTapped: \(collectible.name)")
        
        if collectible.isCollected {
            return
        }
        
        collectionManager.collectItem(collectible, routeType: route.specialRouteType)
        
        lastCollectedItem = collectible.name
        withAnimation(.easeInOut(duration: 0.3)) {
            showingCollectionSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCollectionSuccess = false
            }
        }
        
        updateDebugInfo()
    }
    
    private func startNavigationTimer() {
        print("🎯 DEBUG: 开始导航定时器")
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            currentSpeed = String(Int.random(in: 20...60))
            updateNavigationInfo()
            updateUserLocation()
            updateDebugInfo()
            
            // 自动推进导航
            if isNavigating && Int.random(in: 1...3) == 1 {
                if currentLocationIndex < route.instructions.count - 1 {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        currentLocationIndex += 1
                    }
                    print("🎯 DEBUG: 自动推进到指令 \(currentLocationIndex + 1)")
                }
            }
        }
    }
    
    private func stopNavigationTimer() {
        print("🎯 DEBUG: 停止导航定时器")
        timer?.invalidate()
        timer = nil
    }
    
    private func updateNavigationInfo() {
        let remaining = route.instructions.count - currentLocationIndex
        remainingTime = "\(remaining * 2)分钟"
        remainingDistance = String(format: "%.1f公里", Double(remaining) * 0.3)
    }
    
    private func updateDebugInfo() {
        let stats = collectionManager.getCollectionStats()
        debugInfo = "步骤:\(currentLocationIndex+1)/\(route.instructions.count) | 收集:\(stats.total) | AR:\(showARContent ? "开启" : "关闭") | 导航:\(isNavigating ? "进行中" : "暂停")"
    }
}

// MARK: - 增强的AR场景视图（带导航指引）

struct EnhancedARSceneViewWithGuides: UIViewRepresentable {
    @Binding var currentInstruction: NavigationInstruction?
    @Binding var isNavigating: Bool
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var arSessionStatus: String
    
    let collectionManager: CollectionManager
    let route: RouteInfo
    let onCollectionTapped: (CollectiblePoint) -> Void
    
    func makeUIView(context: Context) -> ARSCNView {
        print("🎯 DEBUG: 创建AR场景视图")
        
        let arView = ARSCNView()
        
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(configuration)
            print("  ✅ AR会话启动成功")
            DispatchQueue.main.async {
                arSessionStatus = "AR就绪"
            }
        } else {
            print("  ❌ AR不支持")
            DispatchQueue.main.async {
                arSessionStatus = "AR不支持"
            }
        }
        
        arView.delegate = context.coordinator
        
        // 设置场景
        arView.scene = SCNScene()
        arView.antialiasingMode = .multisampling4X
        arView.preferredFramesPerSecond = 60
        
        // 启用默认光照
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.updateARContent(
            arView: uiView,
            instruction: currentInstruction,
            isNavigating: isNavigating,
            userLocation: userLocation,
            collectionManager: collectionManager,
            route: route,
            onCollectionTapped: onCollectionTapped
        )
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        private var navigationNodes: [SCNNode] = []
        private var collectibleNodes: [String: (node: SCNNode, collectible: CollectiblePoint)] = [:]
        
        func updateARContent(
            arView: ARSCNView,
            instruction: NavigationInstruction?,
            isNavigating: Bool,
            userLocation: CLLocationCoordinate2D?,
            collectionManager: CollectionManager,
            route: RouteInfo,
            onCollectionTapped: @escaping (CollectiblePoint) -> Void
        ) {
            print("🎯 DEBUG: 更新AR内容")
            
            // 清除旧的导航节点
            clearNavigationNodes()
            
            // 添加明确的导航指引
            if let instruction = instruction {
                print("  🧭 添加导航指引: \(instruction.instruction)")
                createVisibleNavigationGuides(arView: arView, instruction: instruction)
            }
            
            // 更新收集点
            updateCollectibleNodes(
                arView: arView,
                userLocation: userLocation,
                collectionManager: collectionManager,
                onCollectionTapped: onCollectionTapped
            )
        }
        
        private func clearNavigationNodes() {
            for node in navigationNodes {
                node.removeFromParentNode()
            }
            navigationNodes.removeAll()
        }
        
        // 创建明显可见的导航指引
        private func createVisibleNavigationGuides(arView: ARSCNView, instruction: NavigationInstruction) {
            // 1. 创建大号导航箭头（直接在用户前方）
            let arrowGeometry = createLargeArrowGeometry()
            let arrowNode = SCNNode(geometry: arrowGeometry)
            
            // 设置明亮的材质
            let arrowMaterial = SCNMaterial()
            arrowMaterial.diffuse.contents = UIColor.systemBlue
            arrowMaterial.emission.contents = UIColor.blue.withAlphaComponent(0.7) // 强发光
            arrowMaterial.metalness.contents = 0.0
            arrowMaterial.roughness.contents = 0.3
            arrowGeometry.materials = [arrowMaterial]
            
            // 位置：用户前方2米，高度1.5米
            arrowNode.position = SCNVector3(0, 1.5, -2)
            
            // 根据指令类型调整箭头朝向
            let rotationAngle = getRotationAngleForInstruction(instruction.icon)
            arrowNode.eulerAngles = SCNVector3(0, rotationAngle, 0)
            
            // 添加强烈的脉动动画
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.3, duration: 0.6),
                SCNAction.scale(to: 1.0, duration: 0.6)
            ])
            let repeatPulse = SCNAction.repeatForever(pulseAction)
            arrowNode.runAction(repeatPulse)
            
            arView.scene.rootNode.addChildNode(arrowNode)
            navigationNodes.append(arrowNode)
            
            // 2. 创建指令文字（更大、更明显）
            let textGeometry = SCNText(string: instruction.instruction, extrusionDepth: 0.05)
            textGeometry.font = UIFont.boldSystemFont(ofSize: 0.15) // 更大字体
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.8)
            
            let textNode = SCNNode(geometry: textGeometry)
            
            // 居中文字
            let (min, max) = textGeometry.boundingBox
            let textWidth = max.x - min.x
            textNode.position = SCNVector3(-textWidth / 2, 2.0, -2)
            
            // 文字始终面向用户
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            textNode.constraints = [billboardConstraint]
            
            arView.scene.rootNode.addChildNode(textNode)
            navigationNodes.append(textNode)
            
            // 3. 创建距离指示器
            let distanceText = SCNText(string: instruction.distance, extrusionDepth: 0.03)
            distanceText.font = UIFont.systemFont(ofSize: 0.12)
            distanceText.firstMaterial?.diffuse.contents = UIColor.systemGreen
            distanceText.firstMaterial?.emission.contents = UIColor.green.withAlphaComponent(0.6)
            
            let distanceNode = SCNNode(geometry: distanceText)
            
            let (distMin, distMax) = distanceText.boundingBox
            let distWidth = distMax.x - distMin.x
            distanceNode.position = SCNVector3(-distWidth / 2, 0.8, -2)
            
            // 距离文字也面向用户
            let distanceBillboard = SCNBillboardConstraint()
            distanceBillboard.freeAxes = [.Y]
            distanceNode.constraints = [distanceBillboard]
            
            arView.scene.rootNode.addChildNode(distanceNode)
            navigationNodes.append(distanceNode)
            
            // 4. 添加路径指示线（从用户位置指向目标方向）
            createPathIndicatorLine(arView: arView, instruction: instruction)
            
            print("  ✅ AR导航指引创建完成")
        }
        
        // 创建路径指示线
        private func createPathIndicatorLine(arView: ARSCNView, instruction: NavigationInstruction) {
            // 创建一条从用户前方延伸的指示线
            let lineGeometry = SCNCylinder(radius: 0.02, height: 3.0)
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.8)
            lineMaterial.emission.contents = UIColor.blue.withAlphaComponent(0.4)
            lineGeometry.materials = [lineMaterial]
            
            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = SCNVector3(0, 0.5, -2.5) // 地面上方0.5米
            lineNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0) // 水平放置
            
            // 添加流动动画
            let flowAction = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.3, duration: 1.0),
                SCNAction.fadeOpacity(to: 1.0, duration: 1.0)
            ])
            let repeatFlow = SCNAction.repeatForever(flowAction)
            lineNode.runAction(repeatFlow)
            
            arView.scene.rootNode.addChildNode(lineNode)
            navigationNodes.append(lineNode)
        }
        
        // 创建大号箭头几何体
        private func createLargeArrowGeometry() -> SCNGeometry {
            let arrowPath = UIBezierPath()
            
            // 更大的箭头
            arrowPath.move(to: CGPoint(x: 0, y: 0.5))      // 箭头顶部
            arrowPath.addLine(to: CGPoint(x: -0.3, y: 0.2)) // 左翼
            arrowPath.addLine(to: CGPoint(x: -0.15, y: 0.2)) // 左内角
            arrowPath.addLine(to: CGPoint(x: -0.15, y: -0.5)) // 左下
            arrowPath.addLine(to: CGPoint(x: 0.15, y: -0.5))  // 右下
            arrowPath.addLine(to: CGPoint(x: 0.15, y: 0.2))   // 右内角
            arrowPath.addLine(to: CGPoint(x: 0.3, y: 0.2))    // 右翼
            arrowPath.close()
            
            let arrowShape = SCNShape(path: arrowPath, extrusionDepth: 0.1)
            return arrowShape
        }
        
        // 根据指令获取箭头旋转角度
        private func getRotationAngleForInstruction(_ iconName: String) -> Float {
            switch iconName {
            case "arrow.turn.up.left", "arrow.up.left":
                return Float.pi / 4 // 45度左转
            case "arrow.turn.up.right", "arrow.up.right":
                return -Float.pi / 4 // 45度右转
            case "arrow.uturn.left":
                return Float.pi // 180度掉头
            case "arrow.up":
                return 0 // 直行
            default:
                return 0
            }
        }
        
        // 更新收集点显示（保持原有逻辑）
        private func updateCollectibleNodes(
            arView: ARSCNView,
            userLocation: CLLocationCoordinate2D?,
            collectionManager: CollectionManager,
            onCollectionTapped: @escaping (CollectiblePoint) -> Void
        ) {
            guard let userLocation = userLocation else { return }
            
            let collectiblesInRange = collectionManager.collectiblesInRange(of: userLocation)
            
            // 移除不在范围内的收集点
            let currentCollectibleIds = Set(collectiblesInRange.map { $0.id.uuidString })
            let nodesToRemove = collectibleNodes.keys.filter { !currentCollectibleIds.contains($0) }
            
            for nodeId in nodesToRemove {
                collectibleNodes[nodeId]?.node.removeFromParentNode()
                collectibleNodes.removeValue(forKey: nodeId)
            }
            
            // 添加范围内的收集点
            for collectible in collectiblesInRange {
                let nodeId = collectible.id.uuidString
                
                if collectibleNodes[nodeId] == nil && !collectible.isCollected {
                    let collectibleNode = createCollectibleNode(for: collectible, userLocation: userLocation)
                    collectibleNode.name = nodeId
                    arView.scene.rootNode.addChildNode(collectibleNode)
                    collectibleNodes[nodeId] = (node: collectibleNode, collectible: collectible)
                }
            }
        }
        
        // 创建收集点节点（保持原有逻辑但稍作优化）
        private func createCollectibleNode(for collectible: CollectiblePoint, userLocation: CLLocationCoordinate2D) -> SCNNode {
            let node = SCNNode()
            
            let distance = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                .distance(from: CLLocation(latitude: collectible.coordinate.latitude, longitude: collectible.coordinate.longitude))
            
            let deltaLat = collectible.coordinate.latitude - userLocation.latitude
            let deltaLng = collectible.coordinate.longitude - userLocation.longitude
            let angle = atan2(deltaLng, deltaLat)
            
            let displayDistance = min(distance / 20, 3.0)
            
            let x = Float(displayDistance * sin(Double(angle)))
            let z = -Float(displayDistance * cos(Double(angle)))
            let y = Float(1.2) // 稍微降低高度
            
            node.position = SCNVector3(x, y, z)
            
            // 创建收集点几何体
            let sphere = SCNSphere(radius: 0.1)
            let material = SCNMaterial()
            
            let color = getUIColorForCategory(collectible.category)
            material.diffuse.contents = color
            material.emission.contents = color.withAlphaComponent(0.5)
            sphere.materials = [material]
            
            let sphereNode = SCNNode(geometry: sphere)
            node.addChildNode(sphereNode)
            
            // 添加脉动动画
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.2, duration: 0.8),
                SCNAction.scale(to: 1.0, duration: 0.8)
            ])
            sphereNode.runAction(SCNAction.repeatForever(pulseAction))
            
            return node
        }
        
        private func getUIColorForCategory(_ category: CollectibleCategory) -> UIColor {
            switch category.color {
            case "orange": return .systemOrange
            case "green": return .systemGreen
            case "blue": return .systemBlue
            case "purple": return .systemPurple
            case "red": return .systemRed
            default: return .systemGray
            }
        }
        
        // MARK: - ARSCNViewDelegate
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // AR会话更新
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ AR会话失败: \(error.localizedDescription)")
            DispatchQueue.main.async {
                // 通过绑定更新状态
            }
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ AR会话被中断")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("✅ AR会话中断结束")
        }
    }
}

// MARK: - 收集点信息弹窗（复用之前的组件）

struct CollectibleInfoSheet: View {
    let collectible: CollectiblePoint
    let onCollect: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(colorForCategory(collectible.category).opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: collectible.category.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(colorForCategory(collectible.category))
                }
                
                Text(collectible.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(collectible.category.rawValue)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorForCategory(collectible.category).opacity(0.2))
                    )
                    .foregroundColor(colorForCategory(collectible.category))
            }
            
            Text(collectible.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            HStack(spacing: 20) {
                Button("取消") {
                    onDismiss()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary, lineWidth: 1)
                )
                
                Button(collectible.isCollected ? "已收集" : "收集") {
                    if !collectible.isCollected {
                        onCollect()
                    } else {
                        onDismiss()
                    }
                }
                .disabled(collectible.isCollected)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(collectible.isCollected ? Color.gray : colorForCategory(collectible.category))
                )
            }
        }
        .padding()
    }
    
    private func colorForCategory(_ category: CollectibleCategory) -> Color {
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
