//
//  ARNavigationView.swift
//  HelloWorld
//
//  真正的ARKit增强现实导航视图
//

import SwiftUI
import ARKit
import SceneKit
import MapKit

// ARKit场景视图
struct ARSceneView: UIViewRepresentable {
    @Binding var currentInstruction: NavigationInstruction?
    @Binding var isNavigating: Bool
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        // 启用位置追踪（如果设备支持）
        if ARWorldTrackingConfiguration.supportsUserFaceTracking {
            configuration.userFaceTrackingEnabled = false
        }
        
        arView.session.run(configuration)
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
        context.coordinator.updateARContent(arView: uiView, instruction: currentInstruction, isNavigating: isNavigating)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        private var arrowNode: SCNNode?
        private var textNode: SCNNode?
        private var distanceNode: SCNNode?
        
        func updateARContent(arView: ARSCNView, instruction: NavigationInstruction?, isNavigating: Bool) {
            // 清除之前的内容
            arrowNode?.removeFromParentNode()
            textNode?.removeFromParentNode()
            distanceNode?.removeFromParentNode()
            
            guard let instruction = instruction else { return }
            
            // 创建3D箭头指示
            createDirectionArrow(arView: arView, instruction: instruction)
            
            // 创建浮动文字
            createFloatingText(arView: arView, instruction: instruction)
            
            // 创建距离指示
            createDistanceIndicator(arView: arView, instruction: instruction)
        }
        
        private func createDirectionArrow(arView: ARSCNView, instruction: NavigationInstruction) {
            // 创建箭头几何体
            let arrowGeometry = createArrowGeometry()
            arrowNode = SCNNode(geometry: arrowGeometry)
            
            // 设置箭头材质
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemBlue
            material.emission.contents = UIColor.blue.withAlphaComponent(0.3)
            material.metalness.contents = 0.8
            material.roughness.contents = 0.2
            arrowGeometry.materials = [material]
            
            // 定位箭头（在用户前方2米，高度1.5米）
            arrowNode?.position = SCNVector3(0, 1.5, -2)
            
            // 根据导航指令旋转箭头
            let rotationAngle = getRotationAngle(for: instruction.icon)
            arrowNode?.eulerAngles = SCNVector3(0, rotationAngle, 0)
            
            // 添加脉动动画
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.2, duration: 0.8),
                SCNAction.scale(to: 1.0, duration: 0.8)
            ])
            let repeatAction = SCNAction.repeatForever(pulseAction)
            arrowNode?.runAction(repeatAction)
            
            // 添加到场景
            if let arrowNode = arrowNode {
                arView.scene.rootNode.addChildNode(arrowNode)
            }
        }
        
        private func createFloatingText(arView: ARSCNView, instruction: NavigationInstruction) {
            // 创建3D文字
            let textGeometry = SCNText(string: instruction.instruction, extrusionDepth: 0.02)
            textGeometry.font = UIFont.boldSystemFont(ofSize: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.5)
            
            textNode = SCNNode(geometry: textGeometry)
            
            // 居中文字
            let (min, max) = textGeometry.boundingBox
            let textWidth = max.x - min.x
            textNode?.position = SCNVector3(-textWidth / 2, 2.2, -2)
            
            // 文字始终面向用户
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            textNode?.constraints = [billboardConstraint]
            
            // 添加浮动动画
            let floatAction = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 2.0),
                SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: 2.0)
            ])
            let repeatFloat = SCNAction.repeatForever(floatAction)
            textNode?.runAction(repeatFloat)
            
            if let textNode = textNode {
                arView.scene.rootNode.addChildNode(textNode)
            }
        }
        
        private func createDistanceIndicator(arView: ARSCNView, instruction: NavigationInstruction) {
            // 创建距离显示
            let distanceText = SCNText(string: instruction.distance, extrusionDepth: 0.01)
            distanceText.font = UIFont.systemFont(ofSize: 0.08)
            distanceText.firstMaterial?.diffuse.contents = UIColor.systemGreen
            distanceText.firstMaterial?.emission.contents = UIColor.green.withAlphaComponent(0.3)
            
            distanceNode = SCNNode(geometry: distanceText)
            
            // 定位距离文字
            let (min, max) = distanceText.boundingBox
            let textWidth = max.x - min.x
            distanceNode?.position = SCNVector3(-textWidth / 2, 1.0, -2)
            
            // 距离文字也面向用户
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            distanceNode?.constraints = [billboardConstraint]
            
            if let distanceNode = distanceNode {
                arView.scene.rootNode.addChildNode(distanceNode)
            }
        }
        
        private func createArrowGeometry() -> SCNGeometry {
            // 创建一个复杂的3D箭头
            let arrowPath = UIBezierPath()
            
            // 箭头头部
            arrowPath.move(to: CGPoint(x: 0, y: 0.3))
            arrowPath.addLine(to: CGPoint(x: -0.2, y: 0.1))
            arrowPath.addLine(to: CGPoint(x: -0.1, y: 0.1))
            arrowPath.addLine(to: CGPoint(x: -0.1, y: -0.3))
            arrowPath.addLine(to: CGPoint(x: 0.1, y: -0.3))
            arrowPath.addLine(to: CGPoint(x: 0.1, y: 0.1))
            arrowPath.addLine(to: CGPoint(x: 0.2, y: 0.1))
            arrowPath.close()
            
            let arrowShape = SCNShape(path: arrowPath, extrusionDepth: 0.05)
            return arrowShape
        }
        
        private func getRotationAngle(for iconName: String) -> Float {
            switch iconName {
            case "arrow.turn.up.left":
                return Float.pi / 4 // 45度左转
            case "arrow.turn.up.right":
                return -Float.pi / 4 // 45度右转
            case "arrow.up":
                return 0 // 直行
            default:
                return 0
            }
        }
        
        // MARK: - ARSCNViewDelegate
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // 检测到平面时的处理
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // 可以在这里添加平面可视化
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR会话失败: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("AR会话被中断")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("AR会话中断结束")
        }
    }
}

struct ARNavigationView: View {
    let route: RouteInfo
    @Binding var currentLocationIndex: Int
    @Binding var region: MKCoordinateRegion
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    
    @State private var isNavigating = false
    @State private var currentSpeed = "0"
    @State private var remainingTime = ""
    @State private var remainingDistance = ""
    @State private var timer: Timer?
    @State private var showingARUnavailable = false
    
    private var currentInstruction: NavigationInstruction? {
        guard currentLocationIndex < route.instructions.count else { return nil }
        return route.instructions[currentLocationIndex]
    }
    
    var body: some View {
        ZStack {
            // 检查AR可用性
            if ARWorldTrackingConfiguration.isSupported {
                // AR场景视图
                ARSceneView(
                    currentInstruction: .constant(currentInstruction),
                    isNavigating: $isNavigating
                )
                .ignoresSafeArea()
            } else {
                // AR不支持时的降级视图
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        Image(systemName: "camera.metering.unknown")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("AR不支持")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("此设备不支持AR功能\n显示模拟AR界面")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            // AR UI叠加层
            VStack {
                // 顶部状态栏
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.white.opacity(0.8))
                            Text(remainingTime)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .font(.callout)
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.white.opacity(0.8))
                            Text(remainingDistance)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .font(.callout)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Text("\(currentSpeed)")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            Text("km/h")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.callout)
                        
                        HStack {
                            Image(systemName: "arkit")
                                .foregroundColor(.blue)
                            Text("AR导航")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.caption)
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
                
                // 底部控制栏
                HStack(spacing: 40) {
                    // 上一步
                    Button(action: {
                        if currentLocationIndex > 0 {
                            withAnimation {
                                currentLocationIndex -= 1
                            }
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
                            withAnimation {
                                currentLocationIndex += 1
                            }
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
                }
                .padding(.bottom, 50)
            }
            
            // 右侧进度指示器
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Text("步骤")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(currentLocationIndex + 1)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: 40)
                        
                        Text("\(route.instructions.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
            .padding(.top, 200)
        }
        .onAppear {
            updateNavigationInfo()
            
            // 检查AR权限
            checkARSupport()
        }
        .onDisappear {
            stopNavigationTimer()
        }
    }
    
    private func startNavigationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            currentSpeed = String(Int.random(in: 20...60))
            updateNavigationInfo()
            
            // 自动推进导航
            if isNavigating && Int.random(in: 1...3) == 1 {
                if currentLocationIndex < route.instructions.count - 1 {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        currentLocationIndex += 1
                    }
                }
            }
        }
    }
    
    private func stopNavigationTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateNavigationInfo() {
        let remaining = route.instructions.count - currentLocationIndex
        remainingTime = "\(remaining * 2)分钟"
        remainingDistance = String(format: "%.1f公里", Double(remaining) * 0.3)
    }
    
    private func checkARSupport() {
        if !ARWorldTrackingConfiguration.isSupported {
            showingARUnavailable = true
        }
    }
}
